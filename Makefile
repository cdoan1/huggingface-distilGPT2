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

test-local:
	curl http://127.0.0.1:5000/predict \
		-X POST -H "Content-Type: application/json" \
		-d '{"text": "Working late nights on hobby machine learning projects is fun.", "words": "300"}'

test-ocp:

run-local-it:
	@docker run -it -p 5000:5000 \
		${DOCKER_NAMESPACE}/${IMAGE_NAME}:${TAG}

run-local:
	@docker run -d -p 5000:5000 \
		${DOCKER_NAMESPACE}/${IMAGE_NAME}:${TAG}

scalezero:
	@oc scale deployment huggingface --replicas=0 -n huggingface
	@oc delete route huggingface -n huggingface

# on openshift clusters, expose the route to the service
route:
	@oc expose service huggingface -n huggingface

deploy:
	@oc apply -f k8s/deployment.yaml

rollout:
	@oc rollout restart deployment/huggingface
	@oc get pods -o yaml -n huggingface | grep 'imageID'

merge:
	@./hack/travis-merge.sh