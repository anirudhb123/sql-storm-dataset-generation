WITH ranked_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        COALESCE(ARRAY_AGG(DISTINCT ak.name) FILTER (WHERE ak.name IS NOT NULL), '{}') AS actor_names,
        COALESCE(ARRAY_AGG(DISTINCT cn.name) FILTER (WHERE cn.name IS NOT NULL), '{}') AS company_names,
        COALESCE(ARRAY_AGG(DISTINCT kw.keyword) FILTER (WHERE kw.keyword IS NOT NULL), '{}') AS keywords,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY mt.id) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON ci.movie_id = mt.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = mt.movie_id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = mt.movie_id
    LEFT JOIN 
        keyword kw ON kw.id = mk.keyword_id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        mt.id, mt.title, mt.production_year
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    actor_names,
    company_names,
    keywords,
    rank
FROM 
    ranked_movies
WHERE 
    rank <= 10
ORDER BY 
    production_year, rank;
