-- This query retrieves details about movies along with associated actors, roles, and keywords
-- It also benchmarks string processing by applying various string functions and aggregate operations

WITH actor_movie_info AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year AS movie_year,
        rt.role AS role,
        km.keyword AS movie_keyword
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword km ON mk.keyword_id = km.id
    WHERE 
        a.name IS NOT NULL
        AND t.production_year BETWEEN 2000 AND 2023
),

aggregated_info AS (
    SELECT 
        actor_id,
        actor_name,
        STRING_AGG(DISTINCT movie_title, '; ') AS movie_titles,
        STRING_AGG(DISTINCT role, '; ') AS roles,
        STRING_AGG(DISTINCT movie_keyword, '; ') AS keywords,
        COUNT(DISTINCT movie_title) AS movie_count
    FROM 
        actor_movie_info
    GROUP BY 
        actor_id, actor_name
)

SELECT 
    actor_name,
    movie_titles,
    roles,
    keywords,
    movie_count,
    UPPER(actor_name) AS upper_case_name,  -- String manipulation benchmark: converting to uppercase
    LENGTH(actor_name) AS name_length,      -- String manipulation benchmark: getting name length
    REGEXP_REPLACE(actor_name, ' ', '_', 'g') AS replaced_spaces -- Replace spaces with underscores
FROM 
    aggregated_info
ORDER BY 
    movie_count DESC;
