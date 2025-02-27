WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mt.id,
        CONCAT(mh.title, ' (Sequel to: ', mt.title, ')') AS title,
        mt.production_year,
        mh.level + 1
    FROM 
        aka_title mt
    INNER JOIN 
        movie_link ml ON ml.linked_movie_id = mt.id
    INNER JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
    WHERE 
        mh.level < 5  -- Limit nesting to avoid excessive levels
)

SELECT 
    acr.name AS actor_name,
    mt.title AS movie_title,
    mh.production_year,
    ARRAY_AGG(DISTINCT kt.keyword) AS keywords,
    COUNT(mc.company_id) AS production_companies,
    SUM(mi.info IS NOT NULL) AS total_info_count,
    RANK() OVER (PARTITION BY mt.title ORDER BY mh.production_year DESC) AS recent_rank
FROM 
    aka_name acr
JOIN 
    cast_info ci ON ci.person_id = acr.person_id
JOIN 
    movie_companies mc ON mc.movie_id = ci.movie_id
JOIN 
    movie_info mi ON mi.movie_id = ci.movie_id
JOIN 
    movie_keyword mk ON mk.movie_id = ci.movie_id
JOIN 
    keyword kt ON kt.id = mk.keyword_id
JOIN 
    movie_hierarchy mh ON mh.movie_id = ci.movie_id
JOIN 
    aka_title mt ON mt.id = mh.movie_id
WHERE 
    ci.nr_order IS NOT NULL
    AND mt.production_year > (SELECT AVG(production_year) FROM aka_title)
    AND (mc.company_id IS NOT NULL OR mc.note IS NOT NULL)
    AND (mi.info_type_id IS NOT NULL OR mi.info IS NULL)
GROUP BY 
    acr.name, mt.title, mh.production_year
HAVING 
    COUNT(DISTINCT kt.keyword) > 3
ORDER BY 
    recent_rank, acr.name;
