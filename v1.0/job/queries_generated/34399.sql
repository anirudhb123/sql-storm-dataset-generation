WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    mt.title,
    mh.level,
    COUNT(DISTINCT mc.company_id) AS company_count,
    AVG(mk.frequency) AS avg_keyword_frequency,
    MAX(pi.info) AS latest_info,
    COUNT(DISTINCT mw.keyword_id) AS total_keywords
FROM 
    movie_hierarchy mh
JOIN 
    aka_title mt ON mh.movie_id = mt.id
JOIN 
    cast_info ci ON mt.id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON mt.id = mc.movie_id
LEFT JOIN 
    movie_keyword mw ON mt.id = mw.movie_id
LEFT JOIN 
    (SELECT 
         movie_id, 
         COUNT(*) AS frequency 
     FROM 
         movie_keyword 
     GROUP BY 
         movie_id) mk ON mt.id = mk.movie_id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id
WHERE 
    mh.level <= 2
GROUP BY 
    ak.name, mt.title, mh.level
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    mh.level, avg_keyword_frequency DESC, ak.name;
