FROM pytorch/pytorch

RUN mkdir -p /opt/huggingface-distilgpt2/.cache
ENV HOME=/opt/huggingface-distilgpt2
WORKDIR /opt/huggingface-distilgpt2
ADD . /opt/huggingface-distilgpt2

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    python3 python3-dev python3-pip \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN ln -s /usr/bin/python3 /usr/local/bin/python && \
    ln -s /usr/bin/pip3 /usr/local/bin/pip

RUN pip install -r requirements.txt

RUN chgrp -R 0 /opt/huggingface-distilgpt2 \
  && chmod -R g+rwX /opt/huggingface-distilgpt2

EXPOSE 5000

CMD ["python", "/opt/huggingface-distilgpt2/predictor.py"]
