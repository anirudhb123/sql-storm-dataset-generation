WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        aka_title mt
    INNER JOIN 
        movie_link ml ON mt.id = ml.linked_movie_id
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
, ActorInfo AS (
    SELECT 
        ka.id AS actor_id,
        ka.name,
        COUNT(ci.movie_id) AS movie_count,
        STRING_AGG(distinct kt.keyword, ', ') FILTER (WHERE kt.keyword IS NOT NULL) AS keywords
    FROM 
        aka_name ka
    LEFT JOIN 
        cast_info ci ON ka.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = ci.movie_id
    LEFT JOIN 
        keyword kt ON mk.keyword_id = kt.id
    GROUP BY 
        ka.id, ka.name
)
, CompAndInfo AS (
    SELECT 
        mc.movie_id,
        mc.company_id,
        cn.name AS company_name,
        COUNT(DISTINCT ci.id) AS cast_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        complete_cast ci ON mc.movie_id = ci.movie_id
    GROUP BY 
        mc.movie_id, mc.company_id, cn.name
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    ai.actor_id,
    ai.name AS actor_name,
    ai.movie_count AS total_movies,
    ca.company_name,
    ca.cast_count,
    CASE WHEN ai.total_movies IS NULL THEN 'No Movies' ELSE 'Movies Present' END AS movies_status
FROM 
    MovieHierarchy mh
LEFT JOIN 
    ActorInfo ai ON ai.movie_count > 0
LEFT JOIN 
    CompAndInfo ca ON ca.movie_id = mh.movie_id
WHERE 
    mh.production_year IS NOT NULL
    AND (mh.production_year BETWEEN 2010 AND 2020 OR mh.title LIKE '%Adventures%')
ORDER BY 
    mh.production_year DESC,
    ai.name ASC
LIMIT 500;
