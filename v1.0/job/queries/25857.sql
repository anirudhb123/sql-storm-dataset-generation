WITH ranked_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mt.production_year >= 2000
    AND 
        ak.name IS NOT NULL
),
movie_info_details AS (
    SELECT 
        ri.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS additional_info
    FROM 
        ranked_movies ri
    JOIN 
        movie_info mi ON ri.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%award%')
    GROUP BY 
        ri.movie_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.actor_name,
    rm.actor_rank,
    mid.additional_info
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_info_details mid ON rm.movie_id = mid.movie_id
WHERE 
    rm.actor_rank <= 3
ORDER BY 
    rm.production_year DESC, 
    rm.actor_name;
