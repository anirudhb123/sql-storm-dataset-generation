WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.movie_id AS root_movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.root_movie_id
)
SELECT 
    ak.name AS actor_name,
    ak.id AS actor_id,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(mh.root_movie_id) OVER (PARTITION BY ak.id) AS movie_count,
    COALESCE(CAST(SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY ak.id), INTEGER), 0) AS has_notes_count,
    STRING_AGG(DISTINCT kt.keyword, ', ') AS keywords,
    COALESCE(NULLIF(p.info, ''), 'No additional info') AS person_info
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.root_movie_id
LEFT JOIN 
    movie_keyword mk ON mh.root_movie_id = mk.movie_id 
LEFT JOIN 
    keyword kt ON mk.keyword_id = kt.id
LEFT JOIN 
    person_info p ON ak.person_id = p.person_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'biography')
WHERE 
    mh.production_year >= 2000  -- Only movies from the year 2000 onwards
GROUP BY 
    ak.name, ak.id, mh.title, mh.production_year, p.info
ORDER BY 
    movie_count DESC, actor_name ASC;
