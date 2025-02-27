WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        mt.id AS root_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1 AS level,
        mh.root_id
    FROM 
        movie_link ml
    INNER JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS cast_with_notes,
    AVG(CASE WHEN ci.note IS NOT NULL THEN ci.nr_order END) AS avg_order_with_notes,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level
HAVING 
    COUNT(DISTINCT mc.company_id) > 0 AND 
    AVG(CASE WHEN ci.note IS NOT NULL THEN ci.nr_order END) IS NOT NULL
ORDER BY 
    mh.production_year DESC, mh.level, num_companies DESC;
