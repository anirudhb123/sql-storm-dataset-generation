WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title AS t
    JOIN 
        movie_companies AS mc ON t.movie_id = mc.movie_id
    JOIN 
        company_name AS c ON mc.company_id = c.id
    WHERE 
        c.country_code = 'USA'
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy AS mh
    JOIN 
        movie_link AS ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title AS t ON ml.linked_movie_id = t.movie_id
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    STRING_AGG(DISTINCT c.name, ', ') AS company_names,
    MAX(mh.level) AS max_link_level
FROM 
    MovieHierarchy AS m
LEFT JOIN 
    complete_cast AS cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info AS ci ON cc.subject_id = ci.id
LEFT JOIN 
    movie_keyword AS mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    movie_companies AS mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_name AS c ON mc.company_id = c.id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
GROUP BY 
    m.movie_id, m.title, m.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 0
ORDER BY 
    actor_count DESC, 
    keyword_count DESC;
