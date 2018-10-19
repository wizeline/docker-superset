build:
	docker build -t superset .

run:
	docker run --name superset-c -p 8088:8088 -e MAPBOX_API_KEY='' -e LOAD_EXAMPLES=true superset
	#docker run --name superset-c -p 8088:8088 -e MAPBOX_API_KEY='' -e LOAD_EXAMPLES=true 398568613779.dkr.ecr.us-east-1.amazonaws.com/superset-demo
	echo "Superset now running at http://localhost:8088"

stop:
	docker stop superset-c
