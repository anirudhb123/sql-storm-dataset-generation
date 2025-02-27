WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL 
        AND mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
        
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
, actor_movie_count AS (
    SELECT 
        a.id AS actor_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5  -- Actors with more than 5 movies
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(amc.movie_count, 0) AS actor_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    AVG(mv.info_value) AS avg_movie_info
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    actor_movie_count amc ON mc.movie_id = amc.actor_id
LEFT JOIN 
    movie_info mv ON mh.movie_id = mv.movie_id 
WHERE 
    mv.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    AVG(mv.info_value) IS NOT NULL 
    AND COUNT(DISTINCT mc.company_id) > 1 
ORDER BY 
    mh.production_year DESC, actor_count DESC 
FETCH FIRST 10 ROWS ONLY;

