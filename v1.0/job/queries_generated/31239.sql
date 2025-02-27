WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    UNION ALL
    SELECT 
        l.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        movie_link l 
    JOIN 
        aka_title t ON l.linked_movie_id = t.id
    JOIN 
        movie_hierarchy mh ON l.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(DISTINCT c.person_id) AS total_cast,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
    AVG(CASE WHEN m.production_year >= 2010 THEN 1 ELSE NULL END) AS avg_recent,
    SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_present,
    COALESCE(MAX(k.keyword), 'No Keywords') AS top_keyword
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id 
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT c.person_id) > 0
ORDER BY 
    mh.production_year DESC, total_cast DESC;
