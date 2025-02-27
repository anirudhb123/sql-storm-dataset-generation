WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year < 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    COALESCE(mk.keyword, 'No Keyword') AS keyword,
    COUNT(DISTINCT cc.subject_id) OVER (PARTITION BY a.id) AS total_movies,
    mh.level AS movie_level,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = m.id AND mi.info_type_id = 1) AS info_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title m ON ci.movie_id = m.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    complete_cast cc ON m.id = cc.movie_id
JOIN 
    movie_hierarchy mh ON m.id = mh.movie_id
WHERE 
    a.name ILIKE '%Smith%'
    AND (ci.note IS NULL OR ci.note != 'Cameo')
ORDER BY 
    movie_level, total_movies DESC, actor_name;

This SQL query includes a recursive Common Table Expression (CTE) that builds a hierarchy of movies linked to those produced before the year 2000. It joins several tables from the provided schema, utilizes window functions, handles NULL logic, and includes an example of a correlated subquery to retrieve the count of specific movie information types. The result set is ordered by movie level, total movies per actor in descending order, and then actor names alphabetically.
