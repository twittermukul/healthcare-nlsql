"""
MongoDB connection and operations for feedback tickets
"""
from motor.motor_asyncio import AsyncIOMotorClient
from pymongo.errors import ConnectionFailure
from typing import Dict, Any, List, Optional
from datetime import datetime
import logging
from config import settings

logger = logging.getLogger(__name__)


class MongoDBService:
    """MongoDB service for feedback ticket storage"""

    def __init__(self):
        """Initialize MongoDB client"""
        self.client: Optional[AsyncIOMotorClient] = None
        self.db = None
        self.tickets_collection = None

    async def connect(self):
        """Connect to MongoDB"""
        try:
            mongo_url = f"mongodb://{settings.MONGODB_HOST}:{settings.MONGODB_PORT}"
            self.client = AsyncIOMotorClient(mongo_url)

            # Test connection
            await self.client.admin.command('ping')

            # Select database and collection
            self.db = self.client[settings.MONGODB_DB]
            self.tickets_collection = self.db['tickets']

            # Create indexes
            await self.tickets_collection.create_index("ticket_id", unique=True)
            await self.tickets_collection.create_index("created_at")
            await self.tickets_collection.create_index("status")

            logger.info(f"✓ MongoDB connected successfully to {settings.MONGODB_DB}")

        except ConnectionFailure as e:
            logger.error(f"✗ MongoDB connection failed: {str(e)}")
            raise
        except Exception as e:
            logger.error(f"✗ MongoDB initialization error: {str(e)}")
            raise

    async def disconnect(self):
        """Disconnect from MongoDB"""
        if self.client:
            self.client.close()
            logger.info("MongoDB connection closed")

    async def test_connection(self) -> bool:
        """Test MongoDB connection"""
        try:
            if not self.client:
                return False
            await self.client.admin.command('ping')
            return True
        except Exception as e:
            logger.error(f"MongoDB connection test failed: {str(e)}")
            return False

    async def create_ticket(self, ticket_data: Dict[str, Any]) -> str:
        """
        Create a new feedback ticket

        Args:
            ticket_data: Ticket information

        Returns:
            ticket_id: Unique ticket identifier
        """
        try:
            # Generate unique ticket ID with microseconds
            now = datetime.utcnow()
            ticket_id = f"TICKET-{now.strftime('%Y%m%d%H%M%S')}{now.microsecond:06d}"

            # Prepare ticket document
            ticket = {
                "ticket_id": ticket_id,
                "session_id": ticket_data.get("session_id"),
                "created_at": datetime.utcnow(),
                "user_query": ticket_data.get("user_query"),
                "sql_generated": ticket_data.get("sql_generated"),
                "response_data": ticket_data.get("response_data"),
                "issue_description": ticket_data.get("issue_description"),
                "contact_email": ticket_data.get("contact_email"),
                "status": "open",
                "metadata": {
                    "model_used": ticket_data.get("model_used"),
                    "execution_time_ms": ticket_data.get("execution_time_ms"),
                    "row_count": ticket_data.get("row_count")
                }
            }

            # Insert ticket
            result = await self.tickets_collection.insert_one(ticket)

            if result.inserted_id:
                logger.info(f"Ticket created: {ticket_id}")
                return ticket_id
            else:
                raise Exception("Failed to insert ticket")

        except Exception as e:
            logger.error(f"Error creating ticket: {str(e)}")
            raise

    async def get_ticket(self, ticket_id: str) -> Optional[Dict[str, Any]]:
        """Get a ticket by ID"""
        try:
            ticket = await self.tickets_collection.find_one(
                {"ticket_id": ticket_id},
                {"_id": 0}  # Exclude MongoDB ObjectId
            )
            return ticket
        except Exception as e:
            logger.error(f"Error fetching ticket {ticket_id}: {str(e)}")
            return None

    async def get_all_tickets(
        self,
        status: Optional[str] = None,
        limit: int = 100,
        skip: int = 0
    ) -> List[Dict[str, Any]]:
        """
        Get all tickets with optional filtering

        Args:
            status: Filter by status (open/closed/resolved)
            limit: Maximum number of tickets to return
            skip: Number of tickets to skip (pagination)

        Returns:
            List of tickets
        """
        try:
            query = {}
            if status:
                query["status"] = status

            cursor = self.tickets_collection.find(
                query,
                {"_id": 0}
            ).sort("created_at", -1).skip(skip).limit(limit)

            tickets = await cursor.to_list(length=limit)
            return tickets

        except Exception as e:
            logger.error(f"Error fetching tickets: {str(e)}")
            return []

    async def update_ticket_status(
        self,
        ticket_id: str,
        status: str,
        notes: Optional[str] = None
    ) -> bool:
        """Update ticket status"""
        try:
            update_data = {
                "status": status,
                "updated_at": datetime.utcnow()
            }
            if notes:
                update_data["resolution_notes"] = notes

            result = await self.tickets_collection.update_one(
                {"ticket_id": ticket_id},
                {"$set": update_data}
            )

            return result.modified_count > 0

        except Exception as e:
            logger.error(f"Error updating ticket {ticket_id}: {str(e)}")
            return False

    async def get_ticket_stats(self) -> Dict[str, Any]:
        """Get ticket statistics"""
        try:
            total = await self.tickets_collection.count_documents({})
            open_tickets = await self.tickets_collection.count_documents({"status": "open"})
            resolved = await self.tickets_collection.count_documents({"status": "resolved"})
            closed = await self.tickets_collection.count_documents({"status": "closed"})

            return {
                "total": total,
                "open": open_tickets,
                "resolved": resolved,
                "closed": closed
            }
        except Exception as e:
            logger.error(f"Error fetching ticket stats: {str(e)}")
            return {"total": 0, "open": 0, "resolved": 0, "closed": 0}


# Global MongoDB service instance
mongodb_service = MongoDBService()
