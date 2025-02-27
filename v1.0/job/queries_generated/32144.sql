WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        c.person_id,
        MAX(aka.name) AS actor_name,
        CAST(0 AS INTEGER) AS level
    FROM 
        cast_info c
    JOIN 
        aka_name aka ON c.person_id = aka.person_id
    GROUP BY 
        c.person_id

    UNION ALL

    SELECT 
        c.person_id,
        ah.actor_name,
        ah.level + 1
    FROM 
        actor_hierarchy ah
    JOIN 
        cast_info c ON c.movie_id IN (
            SELECT movie_id 
            FROM cast_info 
            WHERE person_id = ah.person_id
        )
    WHERE 
        c.person_id <> ah.person_id
),

movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        ARRAY_AGG(DISTINCT co.name) AS companies
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),

actor_movies AS (
    SELECT 
        ah.actor_name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT md.title, ', ') AS movies
    FROM 
        actor_hierarchy ah
    JOIN 
        cast_info c ON c.person_id = ah.person_id
    JOIN 
        movie_details md ON c.movie_id = md.movie_id
    GROUP BY 
        ah.actor_name
)

SELECT 
    am.actor_name,
    am.movie_count,
    md.company_count,
    md.keyword_count,
    md.movies
FROM 
    actor_movies am
JOIN 
    movie_details md ON am.movies LIKE '%' || md.title || '%'
WHERE 
    am.movie_count > 10
ORDER BY 
    am.movie_count DESC
LIMIT 10;
