from advanced_alchemy.repository import SQLAlchemyAsyncRepository

from app.models.user import UserProfile


class UserRepository(SQLAlchemyAsyncRepository[UserProfile]):
    model_type = UserProfile
