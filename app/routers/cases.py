"""Case management endpoints for OpenClaw."""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from pydantic import BaseModel
from typing import Optional, List
import logging

from database import get_db
from models import Case, CaseStatus, User
from routers.auth import get_current_user

router = APIRouter()
logger = logging.getLogger(__name__)


class CaseCreate(BaseModel):
    title: str
    case_number: Optional[str] = None
    jurisdiction: Optional[str] = None
    court: Optional[str] = None
    description: Optional[str] = None
    content: Optional[str] = None
    tags: Optional[List[str]] = []


class CaseUpdate(BaseModel):
    title: Optional[str] = None
    status: Optional[CaseStatus] = None
    description: Optional[str] = None
    content: Optional[str] = None
    tags: Optional[List[str]] = None


class CaseResponse(BaseModel):
    id: int
    title: str
    case_number: Optional[str]
    jurisdiction: Optional[str]
    court: Optional[str]
    status: str
    description: Optional[str]
    tags: Optional[List[str]]
    owner_id: int

    class Config:
        from_attributes = True


class PaginatedCases(BaseModel):
    items: List[CaseResponse]
    total: int
    page: int
    per_page: int
    pages: int


@router.get("/", response_model=PaginatedCases)
async def list_cases(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    status: Optional[CaseStatus] = None,
    jurisdiction: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = select(Case).where(Case.owner_id == current_user.id)

    if status:
        query = query.where(Case.status == status)
    if jurisdiction:
        query = query.where(Case.jurisdiction == jurisdiction)

    count_result = await db.execute(select(func.count()).select_from(query.subquery()))
    total = count_result.scalar()

    query = query.offset((page - 1) * per_page).limit(per_page).order_by(Case.created_at.desc())
    result = await db.execute(query)
    cases = result.scalars().all()

    return {
        "items": cases,
        "total": total,
        "page": page,
        "per_page": per_page,
        "pages": (total + per_page - 1) // per_page,
    }


@router.post("/", response_model=CaseResponse, status_code=status.HTTP_201_CREATED)
async def create_case(
    case_data: CaseCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    case = Case(**case_data.model_dump(), owner_id=current_user.id)
    db.add(case)
    await db.flush()
    await db.refresh(case)
    return case


@router.get("/{case_id}", response_model=CaseResponse)
async def get_case(
    case_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Case).where(Case.id == case_id, Case.owner_id == current_user.id)
    )
    case = result.scalar_one_or_none()
    if not case:
        raise HTTPException(status_code=404, detail="Case not found")
    return case


@router.put("/{case_id}", response_model=CaseResponse)
async def update_case(
    case_id: int,
    case_data: CaseUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Case).where(Case.id == case_id, Case.owner_id == current_user.id)
    )
    case = result.scalar_one_or_none()
    if not case:
        raise HTTPException(status_code=404, detail="Case not found")

    for field, value in case_data.model_dump(exclude_unset=True).items():
        setattr(case, field, value)

    await db.flush()
    await db.refresh(case)
    return case


@router.delete("/{case_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_case(
    case_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Case).where(Case.id == case_id, Case.owner_id == current_user.id)
    )
    case = result.scalar_one_or_none()
    if not case:
        raise HTTPException(status_code=404, detail="Case not found")

    await db.delete(case)
