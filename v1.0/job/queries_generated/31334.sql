WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1 
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    am.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT m.id) OVER (PARTITION BY am.name) AS movies_count,
    COALESCE(CAST(SUM(nr_order) OVER (PARTITION BY am.name) AS INTEGER), 0) AS total_roles,
    STRING_AGG(DISTINCT k.keyword, ', ') FILTER (WHERE k.keyword IS NOT NULL) AS keywords,
    CASE 
        WHEN MAX(m.production_year) < 2010 THEN 'Pre-2010'
        ELSE 'Post-2010'
    END AS era
FROM 
    aka_name am
JOIN 
    cast_info ci ON am.person_id = ci.person_id
JOIN 
    movie_hierarchy m ON ci.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    am.name IS NOT NULL 
    AND m.production_year IS NOT NULL
GROUP BY 
    am.name, m.title, m.production_year
ORDER BY 
    total_roles DESC, actor_name;
