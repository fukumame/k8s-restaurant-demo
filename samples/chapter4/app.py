from fastapi import FastAPI
from contextlib import asynccontextmanager
import os
import logging

menu_name = os.getenv("MENU_NAME", "本日のシェフおすすめ")
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("仕込みを開始します…")
    logger.info("メニュー: %s", menu_name)
    yield

app = FastAPI(lifespan=lifespan)

@app.get("/menu")
async def read_menu():
    logger.info("注文を受け付けました")
    return {"menu": menu_name}
