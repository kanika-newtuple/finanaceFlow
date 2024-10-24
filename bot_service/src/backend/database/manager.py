from typing import List, Dict, Any
import json

from pocketbase import PocketBase
from pocketbase.client import ClientResponseError
from langchain_chroma import Chroma as LangChainChroma
from pymongo import MongoClient, errors
from sqlalchemy import MetaData, create_engine
from sqlalchemy.engine import URL, Engine
from sqlalchemy.exc import OperationalError
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import scoped_session, sessionmaker
from sqlalchemy.schema import CreateTable

from common.configuration import Configuration
from common.logger import logger
from common.data_model import MongoDBConfiguration, PostgreSQLConfiguation
from contextlib import contextmanager
from LLM.manager import LLMServiceManager


class MongoDBService():

    def __init__(self: str, config: Configuration) -> None:

        super().__init__()
        try:
            # self.client = MongoClient(host=config.configuration().mongodb_configuration.host,
            # port=config.configuration().mongodb_configuration.port, username=config.configuration().mongodb_configuration.username,
            # password=config.configuration().mongodb_configuration.password)
            self.client = MongoClient(
                host=config.configuration().mongodb_configuration.host,
                port=config.configuration().mongodb_configuration.port,
            )
            self.db = self.client.get_database(config.configuration().mongodb_configuration.db)
        except errors.PyMongoError as e:
            logger.critical(f"MongoDB connection was not established due to {e}, skipping..")

    def create_collection_using_docs(self, collection_name: str, documents: list[dict]):
        """
        Create a new collection and populate it with documents.

        This method creates a new collection within an object's associated database with the specified name
        and populates it with the provided list of dictionaries representing the documents.

        Parameters:
            collection_name (str): The name of the collection to be created.
            documents (list[dict]): A list of dictionaries where each dictionary is a document that
                                    will be inserted into the collection upon creation.

        Returns:
            object: An instance or reference to the newly created collection, or detailed information about
                    the success/failure of the operation. The exact return type can depend on the database
                    system being used.
        """

        collection = self.db.get_collection(name=collection_name)
        try:
            ack = collection.insert_many(documents)
            return ack.acknowledged

        except errors.PyMongoError as f:
            error_msg = f"Some error occured while creating mongo collection named {collection_name} with {len(documents)} documents with error {f}."
            logger.debug(error_msg, exc_info=1)
            raise errors.PyMongoError(str(error_msg))

    def drop_collection(self, collection_name: str):
        """
        Drop or delete the specified collection from the database.

        Attempts to remove an existing collection along with all its documents from the database linked
        to this instance. If the operation is successful, an acknowledgment is returned. If any error
        occurs during the process, a message is logged with the error details and no exception is
        raised to the caller.

        Parameters:
        ----------
        collection_name : str
            The name of the collection that needs to be dropped.

        Returns:
        -------
        dict or bool
            An acknowledgment from the drop operation which typically contains information like whether
            the command was acknowledged by the server. May return a boolean `True` if the operation
            does not generate an acknowledgment object but was successful.
        """

        try:
            ack = self.db.drop_collection(name_or_collection=collection_name)
            return ack
        except errors.PyMongoError as f:
            error_msg = f"Some error occurred while dropping mongo collection named {collection_name} with error {f}"
            logger.debug(error_msg, exc_info=1)
            raise errors.PyMongoError(str(error_msg))

    def run_aggregation_pipeline(self, collection_name: str, pipeline: list):
        """
        Executes an aggregation pipeline on the specified MongoDB collection.

        This method applies a sequence of data aggregation operations (stages) to transform and
        combine documents in the specified collection.

        Parameters:
        ----------
        collection_name : str
            The name of the collection to perform the aggregation on.
        pipeline : list
            A list of aggregation pipeline stages to be applied to the collection.

        Returns:
        -------
        list
            A list of dictionaries representing the documents that result from the aggregation.

        Raises:
        ------
        errors.PyMongoError
            If a PyMongo-related error occurs during the aggregation pipeline execution.
        """

        collection = self.db.get_collection(collection_name)
        try:
            aggregate_cursor = collection.aggregate(pipeline)
            aggregate_results = []
            for result in aggregate_cursor:
                if "_id" in result.keys():
                    result["_id"] = str(result["_id"])
                aggregate_results.append(result)

            logger.info(f"Length of the aggregate results {len(aggregate_results)}")

            return aggregate_results
        except errors.PyMongoError as f:
            error_msg = f"Some error occurred while running mongo aggregation pipeline for collection {collection_name} " f"with steps {len(pipeline)} and error {f}"
            logger.debug(error_msg, exc_info=1)
            raise errors.PyMongoError(str(error_msg))

    def get_all_collections(self):
        """
        Retrieves a list of all collection names in the database.

        This method fetches and returns a list of the names of all collections present in the
        MongoDB database associated with this instance.

        Returns:
            list: A list of strings, where each string is the name of a collection in the database.
        """
        try:
            collection_names = self.db.list_collection_names()
            return collection_names
        except errors.PyMongoError as e:
            error_msg = f"An error occurred while fetching collection names: {e}"
            logger.debug(error_msg, exc_info=1)
            raise errors.PyMongoError(str(error_msg))

    def get_samples_and_collections(self):
        samples_per_collection = ""

        try:
            # Get a list of all collections in the database
            collections = self.db.list_collection_names()

            # Dictionary to store collections and their sample documents
            collection_samples = {}

            # Iterate over each collection
            for collection_name in collections:
                collection = self.db[collection_name]

                # Fetch two sample documents from the collection
                sample_docs = collection.find().limit(2)

                # Convert the sample documents to a list
                sample_list = list(sample_docs)

                # Add the collection and its samples to the dictionary
                collection_samples[collection_name] = sample_list

            for collection, documents in collection_samples.items():
                samples_per_collection += f"The collection is : '{collection}'; \n and the sample data for this collection is: "
                for doc in documents:
                    samples_per_collection += str(doc) + " \n\n "
            return samples_per_collection
        except Exception as e:
            error_msg = f"An error occurred while fetching samples and collections: {e}"
            logger.error(error_msg)
            raise Exception(error_msg)


class PostgresDBService():
    def __init__(self, config: Configuration) -> None:
        super().__init__()

        SQLALCHEMY_DATABASE_URL = URL.create(
            drivername="postgresql",
            username=config.configuration().postgresql_configuration.username,
            password=config.configuration().postgresql_configuration.password,
            host=config.configuration().postgresql_configuration.host,
            port=config.configuration().postgresql_configuration.port,
            database=config.configuration().postgresql_configuration.db,
        )
        self.engine = create_engine(
            SQLALCHEMY_DATABASE_URL,
            pool_size=5,
            max_overflow=10,
            pool_pre_ping=True,
        )
        self.base = declarative_base()

    def get_custom_conn(self, config: PostgreSQLConfiguation):

        SQLALCHEMY_DATABASE_URL = URL.create(
            drivername="postgresql",
            username=config.username,
            password=config.password,
            host=config.host,
            port=config.port,
            database=config.db,
        )
        engine = create_engine(
            SQLALCHEMY_DATABASE_URL,
            pool_size=5,
            max_overflow=10,
            pool_pre_ping=True,
        )
        return engine, declarative_base()

    def get_db_session(self):
        sessionlocal = sessionmaker(autocommit=False, autoflush=False, bind=self.engine, expire_on_commit=False)
        db = sessionlocal()
        return db

    def get_gen_db(self):
        sessionlocal = sessionmaker(autocommit=False, autoflush=False, bind=self.engine, expire_on_commit=False)
        db = sessionlocal()
        try:
            yield db
        finally:
            db.close()

    @contextmanager
    def get_custom_db_contxt_session(self, engine: Engine):
        """Creates a context with an open SQLAlchemy session."""
        try:
            connection = engine.connect()
            db_session = scoped_session(sessionmaker(autocommit=False, autoflush=True, bind=engine, expire_on_commit=False))
            yield db_session
            db_session.commit()
        except (OperationalError, BaseException) as e:
            logger.critical(f"Unable to perform postgres db operation due to error {e}, rolling back")
            db_session.rollback()
            raise ValueError(f"Unable to perform postgres db operation due to error {e}, rolling back")
        finally:
            db_session.close()
            connection.close()

    def get_all_table_ddls(self, engine: Engine):
        try:
            table_ddls = []
            meta = MetaData()
            meta.reflect(bind=engine)

            for table in meta.sorted_tables:
                table_ddls.append(CreateTable(table).compile(engine).string)

            return table_ddls
        except BaseException as e:
            logger.error(f"Could not get table ddls due to {e}")
            return []

    def get_all_tables(self, engine: Engine):
        try:
            meta = MetaData()
            meta.reflect(bind=engine)
            return list(meta.tables)
        except BaseException as e:
            logger.error(f"Could not get table ddls due to {e}")
            return []


class ChromaDBService():
    def __init__(self,config: Configuration, llm_service_manager) -> None:
        super().__init__()
        self._database = None
        self.embedding_func = None
        self._llm_service_manager = llm_service_manager
        self._database_directory = config.configuration().vectorDB_configuration.database_directory

    async def prepare(self):
        self.embedding_func = await self._llm_service_manager.openai_service().get_embeddings()
        self._database = LangChainChroma(persist_directory=self._database_directory, embedding_function=self.embedding_func)

    async def search(self, query: str, **kwargs):
        """Searches for API functions based on the given query"""
        logger.info(f"Getting the vector db search for {query}")
        results = self._database.similarity_search(query=query, **kwargs)
        return results

    async def langchain_search(self, query: str, collection, **kwargs):
        """Searches for API functions based on the given query"""
        # self.embedding_func = await self._llm_service_manager.openai_service().get_embeddings()
        chroma_client = LangChainChroma(persist_directory=self._database_directory, embedding_function=self.embedding_func, collection_name=collection)
        results = chroma_client.similarity_search(query=query, **kwargs)
        return results

    async def get_all_collections(self):
        client = chromadb.PersistentClient(path=config.configuration().vectorDB_configuration.database_directory)
        return client.list_collections()


class PocketBaseService:
    """
    Service for interacting with PocketBase.
    """
    def __init__(self, base_url: str):
        self.base_url = base_url
        self.token = None
        self.client = PocketBase(base_url)

    def authenticate(self, email: str, password: str):
        """
        Authenticate with PocketBase.
        """
        try:
            auth_data = self.client.admins.auth_with_password(email, password)
            self.token = auth_data.token
        except ClientResponseError as e:
            logger.error(f"PocketBase admin authentication failed: {e}")
            raise


    def ensure_collection_exists(self, collection_name: str, schema: List[Dict[str, Any]], relation_mapping: Dict[str, str] = None):
        """
        Ensure that a collection exists with the given name and schema.
        If the collection does not exist, it will be created.
        If the collection exists, the existing collection ID will be returned.
        """
        try:
            collections = self.client.collections.get_full_list(query_params={"filter": f"name='{collection_name}'"})
            if not collections:
                logger.info(f"Collection '{collection_name}' does not exist. Attempting to create it.")
                create_data = {
                    "name": collection_name,
                    "type": "base",
                    "schema": [
                        {
                            "name": field["name"],
                            "type": field["type"],
                            "required": field.get("required", False),
                            "options": self._get_field_options(field, relation_mapping)
                        }
                        for field in schema
                    ]
                }
                # Log only serializable parts
                logger.debug(f"Create collection data: {json.dumps({k: v for k, v in create_data.items() if k != 'id'}, indent=2)}")
                try:
                    collection = self.client.collections.create(create_data)
                    logger.info(f"Collection '{collection_name}' created successfully.")
                    logger.info(f"Collection ID: {collection.id}")
                    return collection.id
                except ClientResponseError as create_error:
                    logger.error(f"Failed to create collection '{collection_name}'. Error: {create_error}")
                    logger.error(f"Error details: {create_error.data}")
                    raise
            else:
                logger.info(f"Collection '{collection_name}' already exists.")
                return collections[0].id  # Return the existing collection ID
        except ClientResponseError as e:
            logger.error(f"Error ensuring collection exists: {e}")
            logger.error(f"Error details: {e.data}")
            raise

    def _get_field_options(self, field: Dict[str, Any], relation_mapping: Dict[str, str]) -> Dict[str, Any]:
        """
        Get the field options for a PocketBase field.
        """
        if field["type"] == "relation":
            # Use the relation_mapping to get the correct collectionId
            collection_id = relation_mapping.get(field["name"], None)
            if not collection_id:
                raise ValueError(f"Collection ID for relation field '{field['name']}' is not provided.")
            return {
                "collectionId": collection_id,
                "maxSelect": field.get("options", {}).get("maxSelect", 1),
                "cascadeDelete": field.get("options", {}).get("cascadeDelete", False),
                "displayFields": field.get("options", {}).get("displayFields", None)
            }
        else:
            return field.get("options", {
                "max": 1000000 if field["type"] == "text" else None,
                "maxSize": 5242880 if field["type"] in ["text", "json"] else None
            })

class DatabaseServiceManager:
    """
    Manager for the database service.
    """
    def __init__(self, config: Configuration):
        pocketbase_config = config.configuration().pocketbase_configuration
        self._pocketbase_service = PocketBaseService(pocketbase_config.url)
        try:
            self._pocketbase_service.authenticate(
                pocketbase_config.admin_email,
                pocketbase_config.admin_password
            )
        except Exception as e:
            logger.error(f"Failed to authenticate with PocketBase: {e}")
            # You might want to raise an exception here or handle it in some way
        
        # self._mongo_db_service = MongoDBService(config)
        # self._postgres_db_service = PostgresDBService(config)
        # self._chroma_db_service = ChromaDBService(config, llm_service_manager)

    def pocketbase_service(self) -> PocketBaseService:
        return self._pocketbase_service
    
    def mongo_db_service(self) -> MongoDBService:
        return self._mongo_db_service

    def postgres_db_service(self) -> PostgresDBService:
        return self._postgres_db_service

    def chroma_db_service(self):
        return self._chroma_db_service