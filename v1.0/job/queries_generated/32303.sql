WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id as movie_id,
        mt.title,
        mt.production_year,
        mt.imdb_index,
        1 as hierarchy_level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id as movie_id,
        at.title,
        at.production_year,
        at.imdb_index,
        mh.hierarchy_level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    DISTINCT ak.name as actor_name,
    mt.title as movie_title,
    mt.production_year,
    COUNT(*) OVER (PARTITION BY mt.id) as total_cast,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = mt.id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')) as budget_info_count,
    COALESCE(MAX(k.keyword), 'No Keywords') as keywords
FROM 
    MovieHierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    aka_title mt ON mh.movie_id = mt.id
WHERE 
    mt.production_year >= 2000
    AND ak.name IS NOT NULL 
ORDER BY 
    mt.production_year DESC, mt.title;
