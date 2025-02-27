WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
        
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
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
    at.title AS movie_title,
    mh.production_year,
    mh.depth,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    SUM(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS num_null_notes,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY mh.production_year DESC) AS actor_movie_rank
FROM 
    complete_cast cc
JOIN 
    aka_name ak ON cc.subject_id = ak.person_id
JOIN 
    MovieHierarchy mh ON cc.movie_id = mh.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    cast_info ci ON cc.movie_id = ci.movie_id AND cc.subject_id = ci.person_id
JOIN 
    aka_title at ON mh.movie_id = at.id
GROUP BY 
    ak.name, at.title, mh.production_year, mh.depth
HAVING 
    COUNT(DISTINCT mc.company_id) > 0
ORDER BY 
    mh.depth, mh.production_year DESC, actor_name;
