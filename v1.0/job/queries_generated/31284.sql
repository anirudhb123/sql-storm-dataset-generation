WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ma.linked_movie_id AS movie_id,
        at.title AS movie_title,
        at.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy AS mh
    JOIN 
        movie_link AS ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title AS at ON ml.linked_movie_id = at.id
)

SELECT 
    ak.name AS actor_name,
    mt.movie_title,
    mh.production_year,
    COUNT(DISTINCT mc.company_id) AS num_movie_companies,
    SUM(CASE WHEN mc.note IS NOT NULL THEN 1 ELSE 0 END) AS num_noteed_companies,
    AVG(COALESCE(mk.keyword_count, 0)) AS avg_keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY mh.production_year DESC) AS rank
FROM 
    cast_info AS ci
JOIN 
    aka_name AS ak ON ci.person_id = ak.person_id 
JOIN 
    movie_companies AS mc ON ci.movie_id = mc.movie_id 
JOIN 
    MovieHierarchy AS mh ON ci.movie_id = mh.movie_id 
LEFT JOIN 
    (SELECT 
         movie_id, 
         COUNT(*) AS keyword_count
     FROM 
         movie_keyword
     GROUP BY 
         movie_id) AS mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.production_year >= 2000
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name, mh.movie_title, mh.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    rank, num_movie_companies DESC, production_year;
