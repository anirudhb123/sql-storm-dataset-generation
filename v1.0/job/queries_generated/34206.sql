WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        ci.person_id,
        cm.movie_id,
        1 AS depth
    FROM 
        cast_info ci
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    WHERE 
        at.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ci.person_id,
        cm.movie_id,
        ah.depth + 1
    FROM 
        actor_hierarchy ah
    JOIN 
        cast_info ci ON ah.movie_id = ci.movie_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    WHERE 
        at.production_year >= 2000 AND 
        ah.person_id <> ci.person_id
),
actor_counts AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT a.movie_id) AS movie_count
    FROM 
        actor_hierarchy a
    GROUP BY 
        a.person_id
),
top_actors AS (
    SELECT 
        ac.person_id,
        ac.movie_count,
        ROW_NUMBER() OVER (ORDER BY ac.movie_count DESC) AS rn
    FROM 
        actor_counts ac
    WHERE 
        ac.movie_count > 5
)
SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT mc.movie_id) AS company_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS companies
FROM 
    top_actors ta
JOIN 
    ak_name ak ON ta.person_id = ak.person_id
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    ak.name IS NOT NULL 
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mc.movie_id) > 3
ORDER BY 
    company_count DESC;


