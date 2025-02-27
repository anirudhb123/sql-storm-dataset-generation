WITH ranked_actors AS (
    SELECT 
        ka.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS rn
    FROM 
        aka_name ka
    JOIN 
        cast_info ci ON ka.person_id = ci.person_id
    GROUP BY 
        ka.name
),
movies_with_keywords AS (
    SELECT 
        m.title AS movie_title,
        m.production_year, 
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.title, m.production_year
),
actors_movies AS (
    SELECT 
        ka.name AS actor_name,
        at.title AS movie_title,
        at.production_year
    FROM 
        aka_name ka
    JOIN 
        cast_info ci ON ka.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.id
)
SELECT 
    ra.actor_name, 
    ra.movie_count, 
    mwk.movie_title,
    mwk.production_year,
    mwk.keyword_count
FROM 
    ranked_actors ra
JOIN 
    actors_movies am ON ra.actor_name = am.actor_name
JOIN 
    movies_with_keywords mwk ON am.movie_title = mwk.movie_title 
    AND am.production_year = mwk.production_year
WHERE 
    ra.rn <= 10
ORDER BY 
    ra.movie_count DESC, 
    mwk.keyword_count DESC;