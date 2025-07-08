
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        CAST(m.title AS VARCHAR(255)) AS path
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        h.level + 1,
        CAST(CONCAT(h.path, ' -> ', e.title) AS VARCHAR(255))
    FROM 
        aka_title e
    JOIN 
        movie_hierarchy h ON e.episode_of_id = h.movie_id
)

SELECT 
    mh.movie_id, 
    mh.title, 
    mh.production_year, 
    mh.level,
    mh.path,
    COUNT(DISTINCT c.person_id) AS total_cast,
    LISTAGG(DISTINCT COALESCE(a.name, 'Unknown'), ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names,
    MAX(CASE WHEN r.role IS NOT NULL THEN r.role ELSE 'No Role' END) AS notable_role,
    SUM(CASE WHEN mk.id IS NOT NULL THEN 1 ELSE 0 END) AS keyword_count,
    CASE WHEN SUM(CASE WHEN mk.id IS NOT NULL THEN 1 ELSE 0 END) > 10 THEN 'Popular' ELSE 'Less Popular' END AS popularity
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    role_type r ON c.role_id = r.id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level, mh.path
ORDER BY 
    mh.production_year DESC, 
    total_cast DESC;
