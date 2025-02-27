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
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        mh.depth < 5
),
ActorStats AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(YEAR(CURRENT_DATE) - mt.production_year) AS avg_age
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        aka_title mt ON ci.movie_id = mt.id
    GROUP BY 
        ak.name
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(kw.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.title AS movie_title,
    mh.production_year,
    COALESCE(ak.actor_name, 'Unknown Actor') AS actor_name,
    COALESCE(as.movie_count, 0) AS count_of_movies,
    COALESCE(as.avg_age, 0) AS average_age_of_actor,
    COALESCE(ks.keywords, 'No Keywords') AS keywords
FROM 
    MovieHierarchy mh
LEFT JOIN 
    ActorStats as ON as.movie_count > 0
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    KeywordStats ks ON mh.movie_id = ks.movie_id
WHERE 
    mh.depth = 1
ORDER BY 
    mh.production_year DESC, ak.actor_name ASC
LIMIT 50;
