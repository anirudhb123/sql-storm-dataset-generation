WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
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
    m.id AS movie_id,
    m.title AS movie_title,
    COALESCE(mh.level, 0) AS hierarchy_level,
    ARRAY_AGG(DISTINCT a.name) AS actor_names,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    MAX(CASE WHEN mi.info_type_id IS NOT NULL AND mi.info_type_id = 1 THEN mi.info ELSE NULL END) AS runtime,
    SUM(CASE 
        WHEN c.nr_order IS NULL THEN 0 
        ELSE c.nr_order 
    END) AS total_order
FROM 
    aka_title m
LEFT JOIN 
    cast_info c ON m.id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id
LEFT JOIN 
    movie_hierarchy mh ON m.id = mh.movie_id
WHERE 
    m.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'feature film'))
AND 
    m.production_year IS NOT NULL
GROUP BY 
    m.id, m.title, mh.level
ORDER BY 
    hierarchy_level DESC, m.title
LIMIT 50;

This SQL query uses a recursive Common Table Expression (CTE) to construct a movie hierarchy based on linked movies from 2000 to 2023. It joins multiple tables to gather data about movie titles, actors, keywords, and additional movie info, while also including aggregation functions like `ARRAY_AGG` for actor names and `COUNT` for keyword counts. The query incorporates outer joins, correlated subqueries, and complex predicates, making it suitable for performance benchmarking.
