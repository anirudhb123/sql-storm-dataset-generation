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
        CAST(h.path || ' -> ' || e.title AS VARCHAR(255))
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
    STRING_AGG(DISTINCT COALESCE(a.name, 'Unknown'), ', ') AS cast_names,
    MAX(CASE WHEN r.role IS NOT NULL THEN r.role ELSE 'No Role' END) AS notable_role,
    SUM(mk.id IS NOT NULL) AS keyword_count,
    CASE WHEN SUM(mk.id IS NOT NULL) > 10 THEN 'Popular' ELSE 'Less Popular' END AS popularity
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

This query utilizes a recursive common table expression (CTE) to create a hierarchy of movies and their episodes. It aggregates cast information, including generating a comma-separated list of unique cast names while counting the total number of cast members. It also evaluates the presence of roles, assigns popularity based on keyword occurrences, and orders the final results based on the year of production and total cast count.
