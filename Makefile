build:
	docker build -t superset .

run:
	#docker run -d --name superset -p 8088:8088 tylerfowler/superset
	docker run --name superset-c -p 8088:8088 -e MAPBOX_API_KEY='pk.eyJ1IjoicmVkb2FjcyIsImEiOiJjam1jZmF5N2swZWV2M3FzNGhpajVmaDgyIn0.zlsawn-SdStXqHfBkn1Giw' superset
	echo "Superset now running at http://localhost:8088"

stop:
	docker stop superset-c
