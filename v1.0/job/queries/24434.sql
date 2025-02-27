
WITH ranked_movies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS rank_by_year,
        COUNT(*) OVER (PARTITION BY at.production_year) AS total_movies_per_year
    FROM 
        aka_title at
),
top_movies AS (
    SELECT 
        rm.*
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank_by_year <= 5
),
cast_details AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        STRING_AGG(DISTINCT ak.name, ', ' ORDER BY ak.name) AS actors_list
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
final_result AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        cd.total_actors,
        CASE 
            WHEN cd.total_actors IS NULL THEN 'No Actors' 
            ELSE CAST(cd.total_actors AS VARCHAR)
        END AS actor_count,
        COALESCE(cd.actors_list, 'No actors listed') AS actors
    FROM 
        top_movies tm
    LEFT JOIN 
        cast_details cd ON tm.movie_id = cd.movie_id
)
SELECT 
    fr.title,
    fr.production_year,
    fr.actor_count,
    fr.actors
FROM 
    final_result fr
WHERE 
    fr.production_year > 2000
ORDER BY 
    fr.production_year DESC,
    fr.title ASC
LIMIT 10
OFFSET 5;
