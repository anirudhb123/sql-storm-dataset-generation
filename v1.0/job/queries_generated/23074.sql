WITH ranked_movies AS (
    SELECT 
        a.id AS movie_id,
        at.title,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank,
        at.production_year,
        COALESCE(mk.keyword, 'No Keyword') AS keyword
    FROM 
        aka_title at
    LEFT JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    LEFT JOIN 
        complete_cast cc ON at.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        a.id, at.title, at.production_year, mk.keyword
),
actor_info AS (
    SELECT 
        ak.id AS actor_id,
        ak.name,
        ci.movie_id,
        ci.person_role_id,
        COALESCE(ai.info, 'N/A') AS additional_info
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    LEFT JOIN 
        person_info ai ON ak.person_id = ai.person_id AND ai.info_type_id = 1
    WHERE 
        ak.name IS NOT NULL
),
movie_details AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COUNT(DISTINCT ai.actor_id) AS actor_count,
        STRING_AGG(DISTINCT ai.name, ', ') AS actor_names
    FROM 
        ranked_movies rm
    LEFT JOIN 
        actor_info ai ON rm.movie_id = ai.movie_id
    WHERE 
        rm.rank <= 5
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_count,
    md.actor_names
FROM 
    movie_details md
WHERE 
    md.production_year IS NOT NULL 
    AND md.actor_count > 0
ORDER BY 
    md.production_year DESC, 
    md.actor_count DESC
LIMIT 10;

-- Add a UNION to compare movies with no actors to those with actors
UNION ALL

SELECT 
    at.id AS movie_id,
    at.title,
    at.production_year,
    0 AS actor_count,
    'No Actors' AS actor_names
FROM 
    aka_title at
LEFT JOIN 
    complete_cast cc ON at.id = cc.movie_id
WHERE 
    cc.subject_id IS NULL
    AND at.production_year IS NOT NULL
ORDER BY 
    production_year DESC
LIMIT 10;

This SQL query provides a comprehensive performance benchmarking across various aspects of a movie database, utilizing Common Table Expressions (CTEs), LEFT JOINs, aggregates, window functions, and conditional expressions to handle various scenarios, including cases where actors may not exist for certain movies. The second part of the query further compares this data with movies that have no associated actors in a UNION to ensure a holistic view of the data under examination.
