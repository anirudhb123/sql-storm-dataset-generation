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
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id 
    WHERE 
        at.production_year IS NOT NULL
),
AggregatedCast AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT na.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name na ON ci.person_id = na.person_id
    GROUP BY 
        ci.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info = 'rating' THEN mi.info ELSE NULL END) AS rating,
        MAX(CASE WHEN it.info = 'description' THEN mi.info ELSE NULL END) AS description
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(ac.actor_count, 0) AS actor_count,
    COALESCE(ac.actor_names, 'None') AS actor_names,
    COALESCE(mi.rating, 'N/A') AS rating,
    mi.description
FROM 
    MovieHierarchy mh
LEFT JOIN 
    AggregatedCast ac ON mh.movie_id = ac.movie_id
LEFT JOIN 
    MovieInfo mi ON mh.movie_id = mi.movie_id
WHERE 
    mh.level <= 2 -- Limiting to 2 levels of linked movies
ORDER BY 
    mh.production_year DESC NULLS LAST, 
    mh.title;

This SQL query constructs a recursive common table expression (CTE) to build a hierarchy of movies produced since the year 2000 that may be linked to other titles in a series. It employs several key features, including:

- Recursive CTE (`MovieHierarchy`) to gather movies and their linked counterparts.
- Aggregating actor counts and names with a second CTE (`AggregatedCast`).
- Gathering movie information such as ratings and descriptions in a third CTE (`MovieInfo`).
- Utilizing `LEFT JOIN` to combine results and handle NULL logic effectively, ensuring movies with no associated cast or info are included.
- Conditional aggregation within the CTE to collect different types of movie information.

The final selection orders the results by production year and movie title, applying a limit on the movie hierarchy levels.
