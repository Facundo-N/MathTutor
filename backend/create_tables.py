from database.models import Base
from database.database import engine

Base.metadata.create_all(bind=engine)
print("✅ Tablas creadas: user_sessions, user_signals")
