WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id, 
        at.title, 
        at.production_year, 
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    STRING_AGG(DISTINCT cn.name, ', ') AS companies_list,
    SUM(CASE WHEN mi.info_type_id = it.id THEN 1 ELSE 0 END) AS info_count,
    RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank_by_num_companies,
    ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY ak.name) AS row_num
FROM 
    MovieHierarchy mh
JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
JOIN 
    aka_title mt ON mh.movie_id = mt.id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name, mt.title, mt.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    production_year DESC, num_companies DESC;
