import os

import uvicorn
from fastapi import BackgroundTasks, FastAPI, Request, Response
from kk_logger import logger as app_logging
from kk_request_id.fastapi import RequestId

app = FastAPI()
RequestId(app)


def kill_server():
    app_logging.info("Killing startup server")
    os._exit(0)


@app.get("/")
def startup(request: Request, background_tasks: BackgroundTasks):
    try:
        f = open(".env", "w+")
        env_vars = dict(request.query_params)
        app_logging.info("Startup setting env to: {}".format(env_vars))
        for k, v in env_vars.items():
            f.write(f"{k}={v}\n")
        f.close()
        response = Response("OK", status_code=200)
    except Exception as ex:
        app_logging.critical(f"Exception {ex}", exc_info=True)
        response = Response("error", status_code=500)
    finally:
        background_tasks.add_task(kill_server)

    return response


@app.get("/heart_beat")
def heart_beat():
    return "success"


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8081)
