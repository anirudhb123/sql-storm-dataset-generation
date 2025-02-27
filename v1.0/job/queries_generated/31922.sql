WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name cn ON cn.id = mc.company_id
    WHERE 
        cn.country_code = 'USA'
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        t.title,
        m.production_year,
        depth + 1
    FROM 
        aka_title t
    JOIN 
        movie_link ml ON ml.movie_id = t.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.linked_movie_id
)

SELECT 
    h.movie_id,
    h.title,
    h.production_year,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
    AVG(EXTRACT(YEAR FROM AGE(CURRENT_DATE, h.production_year))) AS avg_years_since_release
FROM 
    movie_hierarchy h
LEFT JOIN 
    complete_cast cc ON cc.movie_id = h.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
LEFT JOIN 
    aka_name a ON a.person_id = ci.person_id
WHERE 
    h.production_year IS NOT NULL
    AND h.production_year >= 2000
GROUP BY 
    h.movie_id, h.title, h.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 5
ORDER BY 
    avg_years_since_release DESC, total_cast DESC;
