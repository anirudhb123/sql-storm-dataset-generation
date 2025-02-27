WITH RECURSIVE MovieHierarchy AS (
    -- Base case: Select all movies
    SELECT mt.id AS movie_id, mt.title, 0 AS level
    FROM aka_title mt
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    -- Recursive case: Select movies linked to others
    SELECT ml.linked_movie_id AS movie_id, at.title, mh.level + 1
    FROM movie_link ml
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title at ON ml.linked_movie_id = at.id
)
SELECT 
    mh.title AS original_movie,
    COUNT(DISTINCT mc.company_id) AS total_companies,
    STRING_AGG(cn.name, ', ') AS companies,
    CASE 
        WHEN AVG(m.production_year) IS NOT NULL THEN AVG(m.production_year) 
        ELSE 0 
    END AS avg_production_year,
    MAX(mh.level) AS depth_of_links
FROM 
    MovieHierarchy mh
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    aka_title m ON mh.movie_id = m.id
WHERE 
    m.production_year IS NOT NULL
GROUP BY 
    mh.title 
HAVING 
    COUNT(DISTINCT mc.company_id) > 0 
    AND MAX(mh.level) > 1 
ORDER BY 
    avg_production_year DESC
LIMIT 10
OFFSET (SELECT COUNT(*) FROM aka_title WHERE kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')) % 10;
