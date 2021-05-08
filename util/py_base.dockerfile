FROM python:3.6-alpine
LABEL Description=本镜像为python应用程序基础镜像
ENV PIP_MIRROR=https://mirrors.aliyun.com/pypi/simple/
COPY . /code
WORKDIR /code
RUN pip install -r requirements.txt -i $PIP_MIRROR
CMD ["python", "app.py"]