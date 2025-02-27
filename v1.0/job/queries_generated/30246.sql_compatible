
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        ak.title,
        ak.production_year,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title ak ON ml.linked_movie_id = ak.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT kc.keyword) DESC) AS rank_by_keywords,
    AVG(CAST(pi.info AS numeric)) FILTER (WHERE pi.info_type_id = 1) AS average_age,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names
FROM 
    movie_hierarchy m
JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
JOIN 
    aka_name ak ON cc.subject_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id
GROUP BY 
    ak.name, m.title, m.production_year
HAVING 
    COUNT(DISTINCT kc.keyword) > 5
ORDER BY 
    m.production_year, rank_by_keywords;
