WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    COALESCE(ak.name, '') AS actor_name,
    ck.keyword,
    mt.info AS movie_info,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY ak.name) AS actor_order,
    COUNT(DISTINCT ml.linked_movie_id) OVER (PARTITION BY mh.movie_id) AS link_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword ck ON mk.keyword_id = ck.id
LEFT JOIN 
    movie_info mt ON mh.movie_id = mt.movie_id
WHERE 
    mh.production_year >= 2000 
    AND (mt.info LIKE '%action%' OR mt.info IS NULL)
ORDER BY 
    mh.production_year, mh.title, actor_order;
