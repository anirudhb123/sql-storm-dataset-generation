WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title AS movie_title, 
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)
SELECT 
    ah.person_name,
    mv.movie_title,
    COALESCE(mv.production_year::TEXT, 'Unknown') AS production_year,
    COUNT(*) OVER (PARTITION BY ah.person_name ORDER BY mv.production_year DESC) AS role_count,
    STRING_AGG(DISTINCT k.keyword, ', ') FILTER (WHERE k.keyword IS NOT NULL) AS keywords
FROM 
    aka_name ah
JOIN 
    cast_info ci ON ci.person_id = ah.person_id
JOIN 
    movie_hierarchy mv ON mv.movie_id = ci.movie_id
LEFT JOIN 
    movie_keyword mk ON mv.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    ah.name IS NOT NULL 
    AND mv.level <= 1
    AND (ah.name ILIKE 'A%' OR ah.name ILIKE 'B%') 
GROUP BY 
    ah.person_name, mv.movie_title
HAVING 
    COUNT(DISTINCT k.keyword) > 1
ORDER BY 
    role_count DESC, production_year DESC;
