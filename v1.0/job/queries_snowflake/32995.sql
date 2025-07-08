
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL  

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1 AS level
    FROM 
        aka_title e
    JOIN 
        movie_hierarchy mh ON e.episode_of_id = mh.movie_id  
)
SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(cc.id) AS total_cast,
    LISTAGG(DISTINCT g.kind, ', ') WITHIN GROUP (ORDER BY g.kind) AS genres,
    ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY mt.production_year DESC) AS rank_within_actor,
    CASE 
        WHEN mt.production_year IS NULL THEN 'Year Not Available' 
        ELSE CAST(mt.production_year AS VARCHAR) 
    END AS production_year_display
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    aka_title mt ON mh.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    kind_type g ON mt.kind_id = g.id
LEFT JOIN 
    complete_cast cc ON mt.id = cc.movie_id
GROUP BY 
    ak.id, ak.name, mt.id, mt.title, mt.production_year
HAVING 
    COUNT(cc.id) > 1  
ORDER BY 
    actor_name, mt.production_year DESC;
