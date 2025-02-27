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
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)
SELECT 
    m.title AS Movie_Title,
    m.production_year AS Production_Year,
    COUNT(DISTINCT ci.person_id) AS Total_Cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS Cast_Names,
    AVG(CASE WHEN pi.info IS NOT NULL THEN LENGTH(pi.info) END) AS Avg_Info_Length,
    COUNT(DISTINCT mc.company_id) FILTER (WHERE ct.kind = 'Production') AS Production_Companies,
    MAX(DATE_PART('year', NOW()) - m.production_year) AS Movie_Age
FROM 
    movie_hierarchy m
LEFT JOIN 
    cast_info ci ON ci.movie_id = m.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = m.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_info mi ON mi.movie_id = m.movie_id
LEFT JOIN 
    person_info pi ON pi.person_id = ci.person_id
GROUP BY 
    m.movie_id, m.title, m.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 5
ORDER BY 
    Movie_Age DESC
LIMIT 100;
