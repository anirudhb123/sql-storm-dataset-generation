WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year = 2020

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        m.production_year IS NOT NULL 
        AND mh.depth < 3  -- Limit depth to avoid infinite recursion
)
SELECT
    a.name AS actor_name,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT ci.person_id) AS total_actors,
    STRING_AGG(DISTINCT ckt.keyword, ', ') AS keywords,
    SUM(CASE WHEN ci.role_id = rt.id THEN 1 ELSE 0 END) AS specific_role_count,
    AVG(m_info.info::numeric) AS average_rating
FROM 
    MovieHierarchy mh
JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword ckt ON mk.keyword_id = ckt.id
LEFT JOIN 
    role_type rt ON ci.role_id = rt.id
LEFT JOIN 
    movie_info m_info ON mh.movie_id = m_info.movie_id AND m_info.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name, mh.title, mh.production_year
ORDER BY 
    total_actors DESC, 
    mh.production_year ASC;
