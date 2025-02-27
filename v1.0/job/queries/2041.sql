WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_year
    FROM 
        aka_title t 
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
movie_cast AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        MAX(ci.nr_order) AS highest_order
    FROM 
        complete_cast mc
    LEFT JOIN 
        cast_info ci ON mc.movie_id = ci.movie_id
    GROUP BY 
        mc.movie_id
),
movie_details AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(mc.total_actors, 0) AS total_actors,
        mc.highest_order,
        CASE 
            WHEN mc.total_actors = 0 THEN 'No Cast'
            WHEN mc.highest_order IS NULL THEN 'No Order Info'
            ELSE 'Info Available'
        END AS cast_info_status
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_cast mc ON rm.movie_id = mc.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.total_actors,
    md.highest_order,
    md.cast_info_status
FROM 
    movie_details md
WHERE 
    md.production_year BETWEEN 2000 AND 2020
ORDER BY 
    md.production_year DESC, md.total_actors DESC
LIMIT 10;