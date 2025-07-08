WITH movie_actors AS (
    SELECT 
        ca.movie_id,
        ak.name AS actor_name,
        COUNT(DISTINCT ca.person_id) AS total_actors
    FROM cast_info ca
    JOIN aka_name ak ON ca.person_id = ak.person_id
    GROUP BY ca.movie_id, ak.name
),
movie_titles AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        COALESCE(mt.kind_id, kt.id) AS kind_id,
        kt.kind AS kind_title
    FROM aka_title mt
    LEFT JOIN kind_type kt ON mt.kind_id = kt.id
),
movie_details AS (
    SELECT 
        ma.movie_id,
        mt.movie_title,
        mt.production_year,
        mt.kind_title,
        ma.actor_name,
        ma.total_actors
    FROM movie_actors ma
    JOIN movie_titles mt ON ma.movie_id = mt.movie_id
),
ranked_movies AS (
    SELECT 
        md.*,
        RANK() OVER (PARTITION BY md.production_year ORDER BY md.total_actors DESC) AS rank_within_year
    FROM movie_details md
)
SELECT 
    r.movie_title,
    r.production_year,
    r.kind_title,
    r.actor_name,
    r.total_actors,
    r.rank_within_year
FROM ranked_movies r
WHERE r.rank_within_year <= 3
ORDER BY r.production_year DESC, r.rank_within_year;
