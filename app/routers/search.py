"""Full-text search endpoints for OpenClaw."""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_
from pydantic import BaseModel
from typing import Optional, List
import logging

from database import get_db
from models import Case, User
from routers.auth import get_current_user

router = APIRouter()
logger = logging.getLogger(__name__)


class SearchResult(BaseModel):
    id: int
    title: str
    case_number: Optional[str]
    jurisdiction: Optional[str]
    court: Optional[str]
    status: str
    relevance_score: Optional[float] = None

    class Config:
        from_attributes = True


class SearchResponse(BaseModel):
    query: str
    results: List[SearchResult]
    total: int
    page: int
    per_page: int


@router.get("/", response_model=SearchResponse)
async def search_cases(
    q: str = Query(..., min_length=2, description="Search query"),
    jurisdiction: Optional[str] = None,
    court: Optional[str] = None,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Search cases by title, content, or case number."""
    query = select(Case).where(
        Case.owner_id == current_user.id,
        or_(
            Case.title.ilike(f"%{q}%"),
            Case.content.ilike(f"%{q}%"),
            Case.case_number.ilike(f"%{q}%"),
            Case.description.ilike(f"%{q}%"),
        ),
    )

    if jurisdiction:
        query = query.where(Case.jurisdiction == jurisdiction)
    if court:
        query = query.where(Case.court == court)

    from sqlalchemy import func
    count_result = await db.execute(select(func.count()).select_from(query.subquery()))
    total = count_result.scalar()

    query = query.offset((page - 1) * per_page).limit(per_page)
    result = await db.execute(query)
    cases = result.scalars().all()

    return {
        "query": q,
        "results": cases,
        "total": total,
        "page": page,
        "per_page": per_page,
    }
