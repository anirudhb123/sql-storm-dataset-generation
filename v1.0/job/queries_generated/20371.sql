WITH ranked_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.id) AS rn,
        COUNT(mk.id) OVER (PARTITION BY mt.id) AS keyword_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    WHERE 
        mt.production_year IS NOT NULL
),
top_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keyword_count
    FROM 
        ranked_movies rm
    WHERE 
        rm.rn <= 10
),
actor_info AS (
    SELECT 
        ak.name,
        ci.note AS role_note,
        ci.nr_order,
        mt.title AS movie_title,
        mt.production_year
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title mt ON ci.movie_id = mt.id
    WHERE 
        ak.name IS NOT NULL AND ci.nr_order IS NOT NULL
),
bizarre_combination AS (
    SELECT 
        ai.name,
        ai.role_note,
        ai.movie_title,
        ai.production_year,
        COALESCE(tmv.keyword_count, 0) AS total_keywords
    FROM 
        actor_info ai
    LEFT JOIN 
        top_movies tmv ON ai.movie_title = tmv.title AND ai.production_year = tmv.production_year
    WHERE 
        ai.role_note NOT LIKE '%extra%' OR 
        (ai.role_note LIKE '%lead%' AND total_keywords = 0)
)
SELECT 
    DISTINCT bc.name AS actor_name,
    bc.movie_title,
    bc.production_year,
    COALESCE(bc.total_keywords, 0) AS keyword_count,
    (SELECT COUNT(DISTINCT movie_id) FROM cast_info ci2 WHERE ci2.person_id = ac.person_id) AS total_movies_by_actor
FROM 
    bizarre_combination bc
JOIN 
    aka_name ac ON bc.name = ac.name
WHERE 
    bc.total_keywords > 2 OR 
    (bc.total_keywords IS NULL AND ac.person_id IN (SELECT person_id FROM cast_info GROUP BY person_id HAVING COUNT(movie_id) > 5))
ORDER BY 
    bc.production_year DESC, 
    bc.actor_name;
