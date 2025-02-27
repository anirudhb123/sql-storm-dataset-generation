WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t 
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        movie_link m
    JOIN 
        aka_title t ON m.linked_movie_id = t.id
    JOIN 
        MovieHierarchy mh ON m.movie_id = mh.movie_id
)
SELECT 
    m.title AS main_movie_title,
    ARRAY_AGG(DISTINCT ak.name) AS alternate_names,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
    COUNT(DISTINCT c.id) AS total_cast,
    AVG(CASE WHEN pi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') THEN pi.info::NUMERIC END) AS avg_rating,
    SUM(CASE WHEN pi.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count,
    m.production_year,
    mh.level AS movie_level
FROM 
    MovieHierarchy mh
JOIN 
    aka_title m ON mh.movie_id = m.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON m.id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    person_info pi ON c.person_id = pi.person_id
WHERE 
    m.production_year >= 2000 
    AND (m.title ILIKE '%adventure%' OR ak.name ILIKE '%Smith%')
GROUP BY 
    m.id, m.title, m.production_year, mh.level
HAVING 
    COUNT(DISTINCT c.id) > 5
ORDER BY 
    avg_rating DESC NULLS LAST;
