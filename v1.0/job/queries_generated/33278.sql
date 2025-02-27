WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT c.id) AS total_cast_members,
    ARRAY_AGG(DISTINCT ki.keyword) AS keywords,
    AVG(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'BoxOffice') THEN CAST(mi.info AS INTEGER) ELSE NULL END) AS average_box_office,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY COUNT(DISTINCT c.id) DESC) AS rank
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    MovieHierarchy mh ON mh.movie_id = t.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND a.name IS NOT NULL
    AND t.title IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year
HAVING 
    COUNT(DISTINCT mi.info_type_id) > 0
ORDER BY 
    rank ASC, total_cast_members DESC;

-- Performance considerations:
-- 1. Using recursive CTE to explore movie relationships via linking.
-- 2. Aggregating distinct keywords related to movies.
-- 3. Including NULL checks to avoid unnecessary complications.
-- 4. Utilizing window functions for ranking on aggregated results.
