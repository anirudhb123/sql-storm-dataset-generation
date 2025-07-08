
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%')
    
    UNION ALL
    
    SELECT 
        cm.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link cm
    JOIN 
        movie_hierarchy mh ON cm.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON cm.linked_movie_id = mt.id
)

SELECT 
    ak.name AS person_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(cc.id) AS cast_count,
    LISTAGG(DISTINCT kt.keyword, ', ') WITHIN GROUP (ORDER BY kt.keyword) AS keywords,
    MAX(CASE WHEN mt.production_year = 2020 THEN 'Recent Release' ELSE 'Older Release' END) AS release_status,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY COUNT(cc.id) DESC) AS actor_rank,
    CASE 
        WHEN COUNT(DISTINCT cc.role_id) > 1 THEN 'Versatile Actor' 
        ELSE 'Typecast Actor' 
    END AS actor_type,
    COALESCE(NULLIF(LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name), ''), 'No Companies') AS production_companies
FROM 
    aka_name ak
JOIN 
    cast_info cc ON ak.person_id = cc.person_id
JOIN 
    movie_hierarchy mh ON cc.movie_id = mh.movie_id
JOIN 
    aka_title mt ON mh.movie_id = mt.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mt.id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mt.id
LEFT JOIN 
    keyword kt ON mk.keyword_id = kt.id
WHERE 
    ak.name IS NOT NULL AND ak.name != ''
GROUP BY 
    ak.name, mt.title, mt.production_year
ORDER BY 
    actor_rank, movie_title
LIMIT 100;
