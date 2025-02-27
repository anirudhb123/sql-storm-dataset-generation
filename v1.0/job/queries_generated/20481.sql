WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level,
        NULL::integer AS parent_id
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m_parent ON m_parent.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON m_parent.id = mh.movie_id
)
SELECT 
    DISTINCT 
    COALESCE(cn.name, 'Unknown') AS character_name,
    ct.kind AS character_type,
    COUNT(DISTINCT ci.movie_id) AS role_count,
    ARRAY_AGG(DISTINCT mt.title) FILTER (WHERE mt.production_year >= 2000) AS recent_movies
FROM 
    char_name cn
LEFT JOIN 
    cast_info ci ON ci.person_id = cn.imdb_id
LEFT JOIN 
    kind_type ct ON ct.id = ci.role_id
LEFT JOIN 
    title mt ON mt.id = ci.movie_id
LEFT JOIN 
    MovieHierarchy mh ON mh.movie_id = ci.movie_id
WHERE 
    cn.name IS NOT NULL
  AND 
    (ci.nr_order IS NULL OR ci.nr_order > 0)
  AND 
    (mt.production_year IS NULL OR mt.production_year < 2023)
GROUP BY 
    character_name, character_type
HAVING 
    COUNT(DISTINCT ci.movie_id) > 3
ORDER BY 
    role_count DESC, character_name ASC
LIMIT 10;
