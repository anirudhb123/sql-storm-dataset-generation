WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)
SELECT 
    m.id AS movie_id,
    m.title,
    m.production_year,
    ARRAY_AGG(DISTINCT CONCAT(a.surname, ', ', a.name)) AS actors,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    AVG(COALESCE(cast_info.nr_order, 0)) AS average_order,
    MAX(m.year) OVER (PARTITION BY m.kind_id) AS max_year_in_kind,
    STRING_AGG(DISTINCT c.name, ', ') AS companies_involved
FROM 
    MovieHierarchy m
LEFT JOIN 
    cast_info ci ON m.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
GROUP BY 
    m.movie_id, m.title, m.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 2 
    AND MAX(m.production_year) > 2000
ORDER BY 
    m.production_year DESC;
