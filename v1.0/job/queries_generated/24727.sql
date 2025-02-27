WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000  -- Select recent movies

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mh.depth < 5  -- Limit recursion depth
)

, RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        RANK() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS title_rank,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.depth) AS depth_rank
    FROM 
        MovieHierarchy mh
)

SELECT
    rm.title,
    rm.production_year,
    COALESCE(ai.name, 'Unknown Actor') AS actor_name,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END) AS has_info_type_1,
    COUNT(DISTINCT mi.info) AS total_info_count
FROM 
    RankedMovies rm
LEFT JOIN 
    cast_info ci ON rm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ai ON ci.person_id = ai.person_id
LEFT JOIN 
    movie_companies mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON rm.movie_id = mi.movie_id
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, ai.name
HAVING
    COUNT(DISTINCT ai.name) > 2  -- Filter for movies with more than 2 distinct actors
ORDER BY 
    rm.production_year DESC,
    depth_rank ASC,
    rm.title ASC;

This query constructs a recursive Common Table Expression (CTE) to gather movies linked to a main list of titles produced since 2000. It employs window functions for ranking films by year while calculating production metrics like the number of companies involved and the presence of specific types of information. It includes LEFT JOINs, aggregates with `STRING_AGG` for keyword collection, and a HAVING clause to filter results. The approach showcases SQL's capabilities to manage complex relational data effectively, while remaining efficient for performance benchmarks.
