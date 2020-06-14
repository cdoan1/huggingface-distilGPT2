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
		-d '{"text": "Working late nights on hobby machine learning projects is fun.", "words": "300"}'

test-ocp:
	@./hack/test-ocp.sh
	@./hack/input.sh https://s23705.pcdn.co/wp-content/uploads/2019/12/roadies-2-e1576036605279.jpg
	@./hack/input.sh https://www.insureandgo.com.au/images/1904-header-oresund-bridge-797x557px_tcm1005-547135.jpg
	@./hack/input.sh https://www.aircraftcompare.com/wp-content/uploads/2019/12/airplane-sunset.jpg
	@./hack/input.sh https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Apple_pie.jpg/1200px-Apple_pie.jpg
	@./hack/input.sh https://www.seatrade-maritime.com/sites/seatrade-maritime.com/files/styles/article_featured_retina/public/Container%20ship%20at%20port%20sunrise.jpg

run-devel:
	@docker run -it -p 5000:5000 \
		${DOCKER_NAMESPACE}/${IMAGE_NAME}:${TAG}

run:
	@docker run -d -p 5000:5000 \
		${DOCKER_NAMESPACE}/${IMAGE_NAME}:${TAG}

imagenet:
	@if [ -f imagenet_class_index.json ]; then rm -rf imagenet_class_index.json; fi
	wget https://raw.githubusercontent.com/raghakot/keras-vis/master/resources/imagenet_class_index.json

scalezero:
	@oc scale deployment image-classifier --replicas=0 -n image-classifier
	@oc delete route image-classifier -n image-classifier

route:
	@oc expose service image-classifier -n image-classifier

deploy:
	@oc apply -f k8s/deployment.yaml

rollout:
	@oc rollout restart deployment/image-classifier
	@oc get pods -o yaml -n image-classifier | grep 'imageID'

merge:
	@./hack/travis-merge.sh