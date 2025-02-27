WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        mt.kind AS movie_type,
        0 AS level
    FROM 
        aka_title m
    JOIN 
        kind_type mt ON m.kind_id = mt.id
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        m.title,
        mt.kind,
        mh.level + 1
    FROM 
        movie_link ml
    INNER JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    INNER JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 3 
)
SELECT 
    h.movie_id,
    h.title,
    h.movie_type,
    COUNT(DISTINCT c.person_id) AS cast_count,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
    STRING_AGG(DISTINCT k.keyword, ', ') AS movie_keywords,
    AVG(m.production_year) OVER (PARTITION BY h.movie_type) AS avg_production_year
FROM 
    movie_hierarchy h
LEFT JOIN 
    cast_info c ON h.movie_id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON h.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    aka_title m ON h.movie_id = m.id
WHERE 
    h.movie_type IS NOT NULL
GROUP BY 
    h.movie_id, h.title, h.movie_type
ORDER BY 
    cast_count DESC, h.title;
