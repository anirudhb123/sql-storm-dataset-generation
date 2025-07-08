WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        title m ON ml.linked_movie_id = m.imdb_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    m.title,
    m.production_year,
    COUNT(DISTINCT c.person_id) AS num_cast_members,
    COUNT(DISTINCT k.keyword) AS num_keywords,
    SUM(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) AS female_cast,
    SUM(CASE WHEN p.gender = 'M' THEN 1 ELSE 0 END) AS male_cast
FROM 
    movie_hierarchy m
LEFT JOIN 
    cast_info c ON m.movie_id = c.movie_id
LEFT JOIN 
    name p ON c.person_id = p.imdb_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    m.production_year IS NOT NULL 
    AND m.production_year BETWEEN 2000 AND 2023 
    AND m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
GROUP BY 
    m.movie_id, m.title, m.production_year
ORDER BY 
    num_cast_members DESC, m.production_year ASC
LIMIT 10;
