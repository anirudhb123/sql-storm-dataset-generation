WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        1 AS level
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.person_id
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 1
    
    UNION ALL

    SELECT 
        ah.person_id,
        ah.movie_count,
        level + 1
    FROM 
        ActorHierarchy ah
    JOIN 
        cast_info ci ON ah.person_id = ci.person_id
    GROUP BY 
        ah.person_id, ah.movie_count
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT ci.movie_id) AS total_movies,
    MAX(t.production_year) AS latest_movie_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS associated_keywords,
    AVG(CASE WHEN ci.role_id IS NULL THEN 0 ELSE 1 END) AS has_role,
    ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS actor_rank
FROM 
    aka_name a
LEFT JOIN 
    cast_info ci ON a.person_id = ci.person_id
LEFT JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT ci.movie_id) > 5
ORDER BY 
    total_movies DESC, latest_movie_year DESC;

WITH MovieStats AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        MIN(m.production_year) AS first_production_year,
        MAX(m.production_year) AS last_production_year
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        aka_title m ON t.id = m.movie_id
    GROUP BY 
        t.id, t.title
)

SELECT 
    movie_id,
    title,
    actor_count,
    keywords,
    (last_production_year - first_production_year) AS year_span
FROM 
    MovieStats
WHERE 
    actor_count > 3
ORDER BY 
    year_span DESC;
