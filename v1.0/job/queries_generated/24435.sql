WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year = 2023

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
    WHERE 
        mh.level < 5
)

SELECT 
    a.name AS actor,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    COUNT(DISTINCT CASE WHEN mw.keyword IS NOT NULL THEN mw.keyword END) AS total_keywords,
    AVG(COALESCE(mi.info_length, 0)) AS avg_info_length,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS rnk,
    CASE 
        WHEN COUNT(DISTINCT c.movie_id) > 10 THEN 'Star'
        WHEN COUNT(DISTINCT c.movie_id) BETWEEN 5 AND 10 THEN 'Supporting'
        ELSE 'Cameo'
    END AS role_category
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    movie_hierarchy mh ON mh.movie_id = c.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = c.movie_id
LEFT JOIN 
    keyword mw ON mk.keyword_id = mw.id
LEFT JOIN 
    (SELECT 
        movie_id,
        AVG(LENGTH(info)) AS info_length
     FROM 
        movie_info 
     WHERE 
        info IS NOT NULL
     GROUP BY 
        movie_id) mi ON mi.movie_id = c.movie_id
WHERE 
    a.name IS NOT NULL
    AND mh.level <= 3
GROUP BY 
    a.name, a.person_id
HAVING 
    COUNT(DISTINCT c.movie_id) > 0
ORDER BY 
    avg_info_length DESC, total_movies DESC, rnk
LIMIT 50;
