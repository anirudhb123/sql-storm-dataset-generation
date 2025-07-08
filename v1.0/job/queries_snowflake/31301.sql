WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        1 AS level, 
        mt.production_year
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id, 
        mt.title, 
        mh.level + 1, 
        mt.production_year
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 3 
)

SELECT 
    mh.movie_id,
    mh.title, 
    mh.production_year, 
    COALESCE(ca.actor_count, 0) AS actor_count, 
    COALESCE(kw.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN mh.production_year < 2010 THEN 'Before 2010' 
        ELSE '2010 and After' 
    END AS production_period
FROM 
    MovieHierarchy mh
LEFT JOIN (
    SELECT 
        ci.movie_id, 
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
) ca ON mh.movie_id = ca.movie_id
LEFT JOIN (
    SELECT 
        mk.movie_id, 
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
) kw ON mh.movie_id = kw.movie_id
ORDER BY 
    mh.production_year DESC, 
    mh.title;