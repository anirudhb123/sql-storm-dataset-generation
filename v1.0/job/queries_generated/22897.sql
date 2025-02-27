WITH ranked_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn,
        COUNT(DISTINCT ci.person_id) AS total_cast
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),

actor_info AS (
    SELECT 
        ak.name AS actor_name,
        ak.person_id,
        STRING_AGG(DISTINCT mt.title, ', ') AS movie_titles
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title mt ON ci.movie_id = mt.id
    GROUP BY 
        ak.name, ak.person_id
),

popular_genre AS (
    SELECT 
        k.keyword,
        COUNT(DISTINCT mt.id) AS genre_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        k.keyword
    HAVING 
        COUNT(DISTINCT mt.id) > 5
),

company_movie_count AS (
    SELECT 
        cn.name AS company_name,
        COUNT(DISTINCT mc.movie_id) AS total_movies
    FROM 
        company_name cn
    JOIN 
        movie_companies mc ON cn.id = mc.company_id
    GROUP BY 
        cn.name
)

SELECT 
    rm.title AS movie_title,
    rm.production_year,
    COALESCE(ai.actor_name, 'Unknown') AS lead_actor,
    COALESCE(ai.movie_titles, 'No titles available') AS actor_movies,
    gm.keyword AS genre,
    cma.company_name,
    cma.total_movies,
    rm.total_cast AS cast_count
FROM 
    ranked_movies rm
LEFT JOIN 
    actor_info ai ON ai.movie_titles LIKE '%' || rm.title || '%'
LEFT JOIN 
    popular_genre gm ON rm.movie_id IN (SELECT movie_id FROM movie_keyword WHERE keyword_id = (SELECT id FROM keyword WHERE keyword = gm.keyword))
LEFT JOIN 
    company_movie_count cma ON cma.total_movies = (SELECT MAX(total_movies) FROM company_movie_count)
WHERE 
    rm.rn = 1
ORDER BY 
    rm.production_year DESC,
    rm.total_cast DESC;
This SQL query achieves multiple goals:
- It ranks movies by the number of distinct cast members per year.
- It collects names and associated movies for each actor.
- It identifies popular genres with more than five associated movies.
- It aggregates company names and counts their produced movies.
- Finally, it brings together these results, providing insights into movies, actors, genres, and companies while handling potential NULLs gracefully.
