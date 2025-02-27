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
        at.title,
        at.production_year,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id 
    WHERE 
        mh.level < 3
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT m.movie_id) AS total_movies,
    AVG(mh.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    CASE 
        WHEN AVG(mh.production_year) IS NULL THEN 'No Data'
        WHEN AVG(mh.production_year) < 2005 THEN 'Early Career'
        ELSE 'Recent Work'
    END AS career_stage,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY COUNT(DISTINCT m.movie_id) DESC) AS rn
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON mc.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    (SELECT 
         DISTINCT mh.movie_id, mh.title, mh.production_year
     FROM 
         movie_hierarchy mh) m ON ci.movie_id = m.movie_id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT m.movie_id) > 2
ORDER BY 
    total_movies DESC, actor_name
LIMIT 10;
