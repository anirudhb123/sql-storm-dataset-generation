WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        0 AS level,
        m.title AS movie_title,
        NULL AS parent_movie_id
    FROM 
        title m
    WHERE 
        m.season_nr IS NULL

    UNION ALL

    SELECT 
        e.id,
        mh.level + 1,
        e.title,
        mh.movie_id AS parent_movie_id
    FROM 
        title e
    JOIN 
        movie_link ml ON e.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.level,
    mh.movie_title,
    COALESCE(a.name, 'Unknown') AS actor_name,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    STRING_AGG(DISTINCT c.kind, ', ') AS company_kinds,
    MAX(m.production_year) AS latest_production_year,
    AVG(CASE WHEN p.info IS NOT NULL THEN LENGTH(p.info) END) AS avg_info_length
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    aka_name a ON cc.subject_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    title m ON mh.movie_id = m.id
LEFT JOIN 
    person_info p ON cc.subject_id = p.person_id
GROUP BY 
    mh.level, mh.movie_title, a.name
ORDER BY 
    mh.level, COUNT(DISTINCT mk.keyword) DESC;
