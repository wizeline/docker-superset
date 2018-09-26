build:
	docker build -t tf-superset .

run:
	#docker run -d --name superset -p 8088:8088 tylerfowler/superset
	docker run --name tf-superset-c -p 8088:8088 -e MAPBOX_API_KEY='pk.eyJ1IjoicmVkb2FjcyIsImEiOiJjam1jZmF5N2swZWV2M3FzNGhpajVmaDgyIn0.zlsawn-SdStXqHfBkn1Giw' tf-superset
	echo "Superset now running at http://localhost:8088"

stop:
	docker stop tf-superset-c
