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
        mlt.linked_movie_id,
        mlt.title,
        mlt.production_year,
        mh.level + 1
    FROM 
        movie_link mlt
    JOIN 
        MovieHierarchy mh ON mlt.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT m.id) AS total_movies,
    AVG(CASE WHEN m.production_year >= 2000 THEN 1 ELSE 0 END) * 100 AS percentage_modern_movies,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY total_movies DESC) AS RN,
    COALESCE(cn.name, 'Unknown Company') AS production_company
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN 
    movie_companies mc ON mt.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mt.id
LEFT JOIN 
    MovieHierarchy mh ON mh.movie_id = mt.id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.id, cn.name
HAVING 
    COUNT(DISTINCT mt.id) > 5
ORDER BY 
    total_movies DESC, percentage_modern_movies DESC
LIMIT 10;
