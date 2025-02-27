
WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        a.name AS actor_name,
        r.role AS actor_role,
        k.keyword AS movie_keyword
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND k.keyword IS NOT NULL
),
unique_keywords AS (
    SELECT DISTINCT
        movie_title,
        ARRAY_AGG(DISTINCT movie_keyword) AS keywords
    FROM 
        movie_details
    GROUP BY 
        movie_title
),
actor_count AS (
    SELECT 
        movie_title,
        COUNT(DISTINCT actor_name) AS unique_actor_count
    FROM 
        movie_details
    GROUP BY 
        movie_title
)
SELECT 
    t.title AS movie_title,
    t.production_year,
    t.kind_id,
    uk.keywords,
    ac.unique_actor_count
FROM 
    unique_keywords uk
JOIN 
    actor_count ac ON uk.movie_title = ac.movie_title
JOIN 
    aka_title t ON uk.movie_title = t.title
ORDER BY 
    ac.unique_actor_count DESC, t.production_year DESC;
