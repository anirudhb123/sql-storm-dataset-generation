WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM aka_title mt
    WHERE mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN aka_title at ON ml.linked_movie_id = at.id
)
, CastMembers AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        ak.title AS movie_title,
        ak.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY ak.production_year DESC) AS movie_rank
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN aka_title ak ON ci.movie_id = ak.id
    WHERE ak.production_year >= 2000
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(DISTINCT cm.actor_id) AS actor_count,
    STRING_AGG(DISTINCT cm.name, ', ') AS actors
FROM MovieHierarchy mh
LEFT JOIN CastMembers cm ON mh.movie_id = cm.movie_title
WHERE mh.level <= 2 -- Limit to movies within 2 levels of the root
GROUP BY mh.movie_id, mh.title, mh.production_year
ORDER BY mh.production_year DESC, actor_count DESC
LIMIT 10;
