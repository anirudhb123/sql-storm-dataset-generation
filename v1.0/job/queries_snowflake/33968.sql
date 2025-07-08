
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year = (SELECT MAX(production_year) FROM aka_title)

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.level,
    mh.title,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names,
    SUM(CASE 
        WHEN mi.info_type_id IS NOT NULL THEN 1 
        ELSE 0 
    END) AS info_count,
    AVG(t.production_year) AS average_year
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = mh.movie_id
JOIN 
    aka_title t ON t.id = mh.movie_id
GROUP BY 
    mh.level, mh.title
ORDER BY 
    mh.level, actor_count DESC;
