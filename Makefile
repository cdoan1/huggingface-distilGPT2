DOCKER_NAMESPACE?=cdoan0
IMAGE_NAME?=huggingface-distilgpt2
TAG?=latest
DOCKER_REGISTRY?=quay.io

NAMESPACE:=huggingface
KUBECTL?=oc

service-name:
  SERVICE?=$(shell $(KUBECTL) get route -n $(NAMESPACE) -o jsonpath="{@.items[0].spec.host}")

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
		-d '{"text": "Working late nights on hobby machine learning projects is fun.", "words": "20"}'

# response is ~14 seconds
test-ocp: service-name
	$(info SERVICE: $(SERVICE))
	curl http://$(SERVICE)/predict \
		-X POST -H "Content-Type: application/json" \
		-d '{"text": "Muge, calm down! Muge! Someone stop her, please!", "words": "20"}'

# repsonse is > gateway timeout, fails
test-ocp-medium: service-name
	$(info SERVICE: $(SERVICE))
	curl http://$(SERVICE)/predict \
		-m 300 \
		-X POST -H "Content-Type: application/json" \
		-d '{"text": "Muge, calm down! Muge! Someone stop her, please!", "words": "70"}'

test-ocp-big: service-name
	$(info SERVICE: $(SERVICE))
	curl http://$(SERVICE)/predict \
		-X POST -H "Content-Type: application/json" \
		-d '{"text": "Muge, calm down! Muge! Someone stop her, please!", "words": "200"}'

run-local-it:
	@docker run -it -p 5000:5000 \
		${DOCKER_NAMESPACE}/${IMAGE_NAME}:${TAG}

run-local:
	@docker run -d -p 5000:5000 \
		${DOCKER_NAMESPACE}/${IMAGE_NAME}:${TAG}

scalezero:
	@oc scale deployment $(NAMESPACE) --replicas=0 -n $(NAMESPACE)
	@oc delete route $(NAMESPACE) -n $(NAMESPACE)

# on openshift clusters, expose the route to the service
route:
	@oc expose service $(NAMESPACE) -n $(NAMESPACE)

deploy:
	@oc apply -f k8s/deployment.yaml

rollout:
	@oc rollout restart deployment/$(NAMESPACE)
	@oc get pods -o yaml -n $(NAMESPACE) | grep 'imageID'
