
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        m.company_id,
        0 AS level
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies m ON t.id = m.movie_id
    WHERE 
        t.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mc.company_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_companies mc ON mh.movie_id = mc.movie_id
    WHERE 
        mh.level < 5
)
SELECT 
    m.title,
    m.production_year,
    c.name AS company_name,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS cast_rank,
    CASE 
        WHEN COUNT(DISTINCT ci.person_id) > 100 THEN 'Large Cast'
        WHEN COUNT(DISTINCT ci.person_id) BETWEEN 50 AND 100 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM 
    aka_title m
LEFT JOIN 
    movie_companies mc ON m.id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    complete_cast cc ON m.id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    m.production_year BETWEEN 2000 AND 2020
    AND c.name IS NOT NULL
GROUP BY 
    m.title, m.production_year, c.name
HAVING 
    COUNT(DISTINCT ci.person_id) > 10
ORDER BY 
    m.production_year DESC, total_cast DESC;
