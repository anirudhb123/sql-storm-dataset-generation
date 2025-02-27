WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title,
        m.production_year,
        m.kind_id,
        1 AS level
    FROM title m
    WHERE m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id, 
        t.title, 
        t.production_year, 
        t.kind_id,
        mh.level + 1
    FROM movie_link ml
    INNER JOIN title t ON ml.linked_movie_id = t.id
    INNER JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.title AS root_movie_title,
    mh.production_year AS root_movie_year,
    mh.level,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    COALESCE(COUNT(DISTINCT mk.keyword), 0) AS keyword_count
FROM MovieHierarchy mh
LEFT JOIN cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN movie_keyword mk ON mh.movie_id = mk.movie_id
WHERE mh.level <= 2
GROUP BY 
    mh.movie_id, 
    mh.title, 
    mh.production_year, 
    mh.level
ORDER BY 
    mh.production_year DESC, 
    actor_count DESC;
