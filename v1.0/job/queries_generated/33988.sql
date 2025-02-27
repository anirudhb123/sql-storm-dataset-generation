WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        mm.id AS movie_id,
        mm.title,
        mm.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mm ON ml.linked_movie_id = mm.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.title AS linked_movie_title,
    mh.production_year AS linked_movie_year,
    ak.name AS actor_name,
    ak.name_pcode_nf AS actor_nationality,
    COUNT(DISTINCT c.movie_id) AS total_movies_linked,
    AVG(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS avg_has_notes
FROM 
    movie_hierarchy mh
JOIN 
    complete_cast c ON mh.movie_id = c.movie_id
JOIN 
    aka_name ak ON ak.person_id = c.subject_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = mh.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
WHERE 
    mh.level < 3 
    AND mh.production_year BETWEEN 2000 AND 2023
    AND EXISTS (
        SELECT 1 FROM movie_keyword mk 
        WHERE mk.movie_id = mh.movie_id 
        AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%Action%')
    )
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, ak.name, ak.name_pcode_nf 
ORDER BY 
    total_movies_linked DESC, linked_movie_year DESC;
