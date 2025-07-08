
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title AS movie_title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    JOIN 
        title t ON m.movie_id = t.id
    WHERE 
        m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        t.title AS movie_title,
        m.production_year,
        level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.movie_id
    JOIN 
        title t ON m.movie_id = t.id
)
SELECT 
    mh.movie_title,
    mh.production_year,
    COUNT(DISTINCT c.id) AS total_cast,
    LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actors,
    AVG(pi.id) AS average_info_type,
    SUM(CASE WHEN mc.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_count,
    RANK() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT c.id) DESC) AS rank_by_cast_size
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
WHERE 
    mh.production_year IS NOT NULL
GROUP BY 
    mh.movie_title, mh.production_year
HAVING 
    COUNT(DISTINCT c.id) > 1 AND 
    AVG(pi.id) IS NOT NULL 
ORDER BY 
    mh.production_year DESC, 
    total_cast DESC;
