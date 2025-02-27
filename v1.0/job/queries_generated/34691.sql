WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title t
    JOIN 
        title m ON m.id = t.movie_id
    WHERE 
        m.production_year >= 2000 
        AND m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')

    UNION ALL

    SELECT 
        mh.movie_id,
        t.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        title t ON ml.linked_movie_id = t.id
    JOIN 
        aka_title m ON m.movie_id = t.id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
)

SELECT 
    a.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY mh.production_year DESC, mt.production_year ASC) AS movie_rank,
    COALESCE(c.kind, 'Unknown') AS char_kind,
    ARRAY_AGG(DISTINCT mk.keyword) AS keywords,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    SUM(mk.id IS NOT NULL) FILTER (WHERE mk.keyword IS NOT NULL) AS keyword_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    char_name c ON a.name = c.name
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
JOIN 
    aka_title mt ON mh.movie_id = mt.movie_id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.id, mt.title, mt.production_year, c.kind
HAVING 
    COUNT(DISTINCT mh.movie_id) > 1
ORDER BY 
    total_movies DESC, movie_rank ASC;

