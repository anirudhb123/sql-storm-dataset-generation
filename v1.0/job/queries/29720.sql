
WITH actor_name AS (
    SELECT 
        ak.person_id AS actor_id,
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.person_id, ak.name
),
movie_details AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        STRING_AGG(DISTINCT cn.name, ', ' ORDER BY cn.name) AS company_names
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
top_actors AS (
    SELECT 
        actor_name.actor_id,
        actor_name.actor_name,
        actor_name.movie_count,
        ROW_NUMBER() OVER (ORDER BY actor_name.movie_count DESC) AS rank
    FROM 
        actor_name
),
ranked_movies AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.movie_title) AS rank_per_year
    FROM 
        movie_details md
)
SELECT 
    ta.actor_name,
    ta.movie_count AS total_movies,
    rm.movie_title,
    rm.production_year,
    rm.rank_per_year
FROM 
    top_actors ta
JOIN 
    cast_info ci ON ta.actor_id = ci.person_id
JOIN 
    ranked_movies rm ON ci.movie_id = rm.movie_id
WHERE 
    ta.rank <= 10 AND rm.rank_per_year <= 5
ORDER BY 
    ta.movie_count DESC, rm.production_year DESC, rm.movie_title;
