WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id
),
high_cast_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank <= 10
),
actor_info AS (
    SELECT 
        ak.name AS actor_name,
        ka.id AS movie_id,
        ka.title
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        high_cast_movies ka ON ci.movie_id = ka.movie_id
)
SELECT 
    a.actor_name,
    h.title,
    h.production_year,
    COUNT(DISTINCT ci.role_id) AS unique_roles
FROM 
    actor_info a
JOIN 
    cast_info ci ON a.movie_id = ci.movie_id
JOIN 
    high_cast_movies h ON a.movie_id = h.movie_id
GROUP BY 
    a.actor_name, h.title, h.production_year
ORDER BY 
    h.production_year DESC, unique_roles DESC;
