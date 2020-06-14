DOCKER_NAMESPACE?=cdoan0
IMAGE_NAME?=huggingface-distilgpt2
TAG?=latest
DOCKER_REGISTRY?=quay.io

build:
	@docker build -t ${DOCKER_NAMESPACE}/${IMAGE_NAME}:${TAG} .

push:
	@if [ -z ${DOCKER_USERNAME} ] || [ -z ${DOCKER_TOKEN} ]; then echo "repo credentials required ..."; exit 1; fi
	@docker login -u="${DOCKER_USERNAME}" -p="${DOCKER_TOKEN}" ${DOCKER_REGISTRY}
	@docker tag ${DOCKER_NAMESPACE}/${IMAGE_NAME}:${TAG} ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/${IMAGE_NAME}:${TAG}
	@docker push ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/${IMAGE_NAME}:${TAG}

test:
	curl http://127.0.0.1:5000/predict \
		-X POST -H "Content-Type: application/json" \
		-d '{"text": "Working late nights on hobby machine learning projects is fun.", "words": "20"}'
	curl http://127.0.0.1:5000/predict \
		-X POST -H "Content-Type: application/json" \
		-d '{"text": "And that is all, Coveralls will automatically work with your Github project because the script when used by Travis will send info about the project and branch he was building.", "words": "100"}'

run-devel:
	@docker run -it -p 5000:5000 \
		${DOCKER_NAMESPACE}/${IMAGE_NAME}:${TAG}

run:
	@docker run -d -p 5000:5000 \
		${DOCKER_NAMESPACE}/${IMAGE_NAME}:${TAG}

scalezero:
	@oc scale deployment ${IMAGE_NAME} --replicas=0 -n ${IMAGE_NAME}
	@oc delete route ${IMAGE_NAME} -n ${IMAGE_NAME}

route:
	@oc expose service ${IMAGE_NAME} -n ${IMAGE_NAME}

deploy:
	@oc apply -f k8s/deployment.yaml

rollout:
	@oc rollout restart deployment/${IMAGE_NAME}
	@oc get pods -o yaml -n ${IMAGE_NAME} | grep 'imageID'

