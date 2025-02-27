WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level,
        NULL::integer AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1,
        mh.movie_id
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mv.title,
    mv.production_year,
    STRING_AGG(DISTINCT an.name, ', ') AS actor_names,
    AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_order,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    COUNT(DISTINCT kw.keyword) AS num_keywords,
    COUNT(DISTINCT mi.info) FILTER (WHERE it.id = 1) AS num_info_type
FROM 
    movie_hierarchy mv
LEFT JOIN 
    complete_cast cc ON cc.movie_id = mv.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = mv.movie_id
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mv.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mv.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON mi.movie_id = mv.movie_id
LEFT JOIN 
    info_type it ON it.id = mi.info_type_id
WHERE 
    mv.level <= 2 
    AND (mv.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%') OR mv.production_year IS NULL)
GROUP BY 
    mv.movie_id, mv.title, mv.production_year
ORDER BY 
    mv.production_year DESC, avg_order DESC
LIMIT 100;
