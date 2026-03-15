"""
SQLAlchemy ORM Models for OpenClaw.
"""
from sqlalchemy import Column, Integer, String, Text, Boolean, ForeignKey, JSON, Enum
from sqlalchemy.orm import relationship
import enum

from database import Base


class UserRole(str, enum.Enum):
    ADMIN = "admin"
    RESEARCHER = "researcher"
    VIEWER = "viewer"


class CaseStatus(str, enum.Enum):
    ACTIVE = "active"
    CLOSED = "closed"
    PENDING = "pending"
    ARCHIVED = "archived"


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    username = Column(String(100), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(255))
    role = Column(Enum(UserRole), default=UserRole.RESEARCHER, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    is_verified = Column(Boolean, default=False, nullable=False)

    cases = relationship("Case", back_populates="owner", cascade="all, delete-orphan")
    searches = relationship("SearchHistory", back_populates="user", cascade="all, delete-orphan")


class Case(Base):
    __tablename__ = "cases"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(500), nullable=False, index=True)
    case_number = Column(String(100), unique=True, index=True)
    jurisdiction = Column(String(100))
    court = Column(String(200))
    status = Column(Enum(CaseStatus), default=CaseStatus.ACTIVE, nullable=False)
    description = Column(Text)
    content = Column(Text)
    tags = Column(JSON, default=list)
    metadata = Column(JSON, default=dict)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)

    owner = relationship("User", back_populates="cases")
    documents = relationship("Document", back_populates="case", cascade="all, delete-orphan")


class Document(Base):
    __tablename__ = "documents"

    id = Column(Integer, primary_key=True, index=True)
    filename = Column(String(500), nullable=False)
    blob_url = Column(String(1000))
    content_type = Column(String(100))
    size_bytes = Column(Integer)
    extracted_text = Column(Text)
    case_id = Column(Integer, ForeignKey("cases.id"), nullable=False)

    case = relationship("Case", back_populates="documents")


class SearchHistory(Base):
    __tablename__ = "search_history"

    id = Column(Integer, primary_key=True, index=True)
    query = Column(Text, nullable=False)
    filters = Column(JSON, default=dict)
    results_count = Column(Integer, default=0)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)

    user = relationship("User", back_populates="searches")
