WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year = 2023

    UNION ALL 

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    ak.name AS actor_name,
    mk.keyword AS movie_keyword,
    mt.production_year,
    COUNT( DISTINCT cc.id) AS total_cast,
    SUM(CASE WHEN cc.id IS NOT NULL THEN 1 ELSE 0 END) AS cast_count,
    COUNT(DISTINCT mh.movie_id) AS total_related_movies,
    STRING_AGG(DISTINCT at.title, ', ') AS related_titles,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY SUM(cc.nr_order) DESC) AS rank
FROM 
    aka_name ak
JOIN 
    cast_info cc ON ak.person_id = cc.person_id
JOIN 
    aka_title at ON cc.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    movie_info mi ON at.id = mi.movie_id
LEFT JOIN 
    movie_hierarchy mh ON at.id = mh.movie_id
WHERE 
    ak.name IS NOT NULL 
AND 
    (mi.info IS NULL OR mi.info_type_id NOT IN (SELECT id FROM info_type WHERE info = 'Spoof'))
AND 
    (mk.keyword IS NOT NULL OR ak.name LIKE '%Smith%')
GROUP BY 
    ak.name, mk.keyword, mt.production_year
HAVING 
    COUNT(DISTINCT cc.id) >= 1
ORDER BY 
    total_related_movies DESC, actor_name;

This SQL query does the following:

1. Creates a recursive Common Table Expression (CTE) called `movie_hierarchy` to get all related movies linked to those produced in 2023.
2. Retrieves detailed aggregated information about actor names, movie keywords, production years, total cast counts, and totals of related movies.
3. Utilizes various joins (inner and left outer joins), as well as string aggregation and window functions (ROW_NUMBER).
4. Implements conditional logic in the `WHERE` clause to filter and exclude specific records.
5. Applies grouping and ordering based on the total of related movies and actor names for a comprehensive performance benchmark.
