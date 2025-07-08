
WITH movie_details AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ak.name) DESC) AS year_rank
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
top_movies AS (
    SELECT 
        movie_title,
        production_year,
        actor_names,
        keyword_count
    FROM 
        movie_details
    WHERE 
        year_rank <= 5
)
SELECT 
    tm.production_year,
    COUNT(*) AS top_movie_count,
    LISTAGG(tm.movie_title, '; ') WITHIN GROUP (ORDER BY tm.movie_title) AS top_movie_titles,
    MAX(tm.keyword_count) AS max_keywords
FROM 
    top_movies tm
GROUP BY 
    tm.production_year
ORDER BY 
    tm.production_year DESC
LIMIT 10;
