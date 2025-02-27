WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.linked_movie_id AS movie_id,
        a.title,
        mh.level + 1 AS level
    FROM 
        movie_link m
    JOIN 
        aka_title a ON m.linked_movie_id = a.id
    JOIN 
        movie_hierarchy mh ON m.movie_id = mh.movie_id
)
SELECT 
    p.name AS person_name,
    t.title AS movie_title,
    mh.level AS hierarchy_level,
    COUNT(DISTINCT c.role_id) AS total_roles,
    COALESCE(SUM(mi.info IS NOT NULL), 0) AS info_count,
    STRING_AGG(DISTINCT c.note, ', ') AS role_notes
FROM 
    movie_hierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.person_id
JOIN 
    aka_name p ON c.person_id = p.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
LEFT JOIN 
    aka_title t ON mh.movie_id = t.id
WHERE 
    mh.level <= 3
    AND c.nr_order < 5
    AND t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    p.name, t.title, mh.level
ORDER BY 
    total_roles DESC, p.name ASC;
