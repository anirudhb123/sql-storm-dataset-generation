
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        'Root' AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        'Child' AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        ml.movie_id IN (SELECT id FROM aka_title WHERE kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie'))
)

SELECT 
    mk.movie_id,
    mt.title AS movie_title,
    mt.production_year,
    COALESCE(ac.name, 'Unknown') AS actor_name,
    COALESCE(CAST(SUM(mk.movie_id) AS VARCHAR), '0') AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS row_num,
    CASE 
        WHEN co.name IS NULL THEN 'Independent'
        ELSE 'Studio'
    END AS company_type,
    COUNT(DISTINCT c.id) AS total_cast_members
FROM 
    movie_hierarchy mk
JOIN 
    aka_title mt ON mk.movie_id = mt.id
LEFT JOIN 
    cast_info c ON mt.id = c.movie_id
LEFT JOIN 
    aka_name ac ON c.person_id = ac.person_id
LEFT JOIN 
    movie_companies mc ON mt.id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id 
WHERE 
    mt.production_year >= 2000
    AND (ac.name IS NOT NULL OR mt.title IS NOT NULL)
GROUP BY 
    mk.movie_id, mt.title, mt.production_year, ac.name, co.name
HAVING 
    SUM(mk.movie_id) > 1
ORDER BY 
    mt.production_year DESC, row_num;
