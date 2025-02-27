WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id, 
        ct.kind AS role, 
        t.title AS movie_title, 
        t.production_year,
        1 AS level
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    JOIN 
        title t ON at.movie_id = t.id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    WHERE 
        ak.name IS NOT NULL 
        AND t.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ci.person_id, 
        ct.kind, 
        t.title AS movie_title,
        t.production_year,
        ah.level + 1
    FROM 
        cast_info ci
    JOIN 
        ActorHierarchy ah ON ci.movie_id = (
            SELECT linked_movie_id 
            FROM movie_link 
            WHERE movie_id = ah.movie_id
            LIMIT 1
        )
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    JOIN 
        title t ON at.movie_id = t.id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    WHERE 
        t.production_year IS NOT NULL
)

SELECT 
    ah.person_id,
    ak.name AS actor_name,
    COLLECT(DISTINCT ah.role) AS roles,
    COUNT(DISTINCT ah.movie_title) AS movie_count,
    AVG(ah.production_year) AS average_year,
    MAX(ah.level) AS max_depth
FROM 
    ActorHierarchy ah
JOIN 
    aka_name ak ON ah.person_id = ak.person_id
GROUP BY 
    ah.person_id, ak.name
HAVING 
    COUNT(DISTINCT ah.movie_title) > 5
ORDER BY 
    average_year DESC;

-- Benchmarking performance using string comparison, null checks, and complex predicates
SELECT 
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
FROM 
    title t
LEFT JOIN 
    cast_info ci ON t.id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND t.title IS NOT NULL
    AND ak.name IS NOT NULL
GROUP BY 
    t.title, t.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) >= 3
ORDER BY 
    total_cast DESC, t.title;
