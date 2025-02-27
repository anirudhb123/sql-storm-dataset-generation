WITH movie_statistics AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT mk.keyword) AS num_keywords,
        COUNT(DISTINCT c.person_id) AS num_cast_members
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id
),

actor_info AS (
    SELECT 
        ak.name AS actor_name,
        ak.person_id,
        COUNT(DISTINCT c.movie_id) AS movies_count,
        STRING_AGG(DISTINCT m.title, ', ') AS movie_titles
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    JOIN 
        aka_title m ON c.movie_id = m.id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.name, ak.person_id
    HAVING 
        COUNT(DISTINCT c.movie_id) > 1
)

SELECT 
    ms.movie_id,
    ms.movie_title,
    ms.production_year,
    ms.num_keywords,
    ms.num_cast_members,
    ai.actor_name,
    ai.movies_count,
    ai.movie_titles
FROM 
    movie_statistics ms
JOIN 
    actor_info ai ON ms.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = ai.person_id)
ORDER BY 
    ms.production_year DESC, ms.num_keywords DESC;
