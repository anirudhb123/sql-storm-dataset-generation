WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level,
        mt.id AS root_movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL 
    
    UNION ALL 

    SELECT 
        ml.linked_movie_id,
        a.title,
        a.production_year,
        mh.level + 1,
        mh.root_movie_id
    FROM 
        MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN aka_title a ON ml.linked_movie_id = a.id
)

SELECT 
    m.id AS movie_id,
    m.title,
    m.production_year,
    COALESCE(ka.name, 'Unknown') AS main_actor,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    AVG(mi.info::numeric) FILTER (WHERE it.info = 'Rating') AS avg_rating,
    MIN(mh.level) AS recursive_depth
FROM 
    MovieHierarchy m
LEFT JOIN 
    cast_info ci ON m.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ka ON ci.person_id = ka.person_id AND ci.nr_order = 1
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    m.production_year >= 2000
    AND m.title IS NOT NULL
GROUP BY 
    m.id, m.title, m.production_year, ka.name
ORDER BY 
    avg_rating DESC NULLS LAST,
    m.production_year DESC;
