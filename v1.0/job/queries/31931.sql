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
        MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN aka_title at ON ml.linked_movie_id = at.id
)
SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(DISTINCT cc.id) AS total_cast_count,
    AVG(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END) AS note_present,
    STRING_AGG(DISTINCT cn.name, ', ') AS character_names,
    ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT cc.id) DESC) AS movie_rank
FROM 
    MovieHierarchy mh
JOIN complete_cast cc ON mh.movie_id = cc.movie_id
JOIN cast_info ci ON cc.subject_id = ci.person_id
JOIN aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN char_name cn ON ci.role_id = cn.id
JOIN aka_title mt ON mh.movie_id = mt.id
WHERE 
    mt.kind_id IN (1, 2) 
GROUP BY 
    ak.name, mt.title, mt.production_year
HAVING 
    COUNT(DISTINCT cc.id) > 5
ORDER BY 
    mt.production_year DESC, movie_rank;