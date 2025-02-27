WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
        JOIN aka_title at ON ml.movie_id = at.id
        JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.depth < 3
),
ActorStats AS (
    SELECT 
        ci.person_id,
        ak.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        ARRAY_AGG(DISTINCT mh.title ORDER BY mh.production_year) AS movies
    FROM 
        cast_info ci
        JOIN aka_name ak ON ci.person_id = ak.person_id
        JOIN MovieHierarchy mh ON ci.movie_id = mh.movie_id
    GROUP BY 
        ci.person_id, ak.name
),
RoleCount AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.role_id) AS distinct_roles
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
)
SELECT 
    a.name,
    a.movie_count,
    a.movies,
    COALESCE(rc.distinct_roles, 0) AS distinct_roles,
    CASE 
        WHEN a.movie_count > 5 THEN 'Prolific Actor'
        WHEN a.movie_count BETWEEN 2 AND 5 THEN 'Regular Actor'
        ELSE 'Emerging Actor'
    END AS actor_type
FROM 
    ActorStats a
LEFT JOIN 
    RoleCount rc ON a.person_id = rc.person_id
WHERE 
    a.movie_count > 1
ORDER BY 
    a.movie_count DESC, a.name;

WITH GenreCount AS (
    SELECT 
        mt.kind_id,
        COUNT(DISTINCT mt.id) AS movie_count
    FROM 
        aka_title mt
    GROUP BY 
        mt.kind_id
),
GenreSummary AS (
    SELECT 
        k.kind AS genre,
        gc.movie_count,
        ROW_NUMBER() OVER (ORDER BY gc.movie_count DESC) AS genre_rank
    FROM 
        kind_type k
    JOIN 
        GenreCount gc ON k.id = gc.kind_id
)
SELECT 
    gs.genre,
    gs.movie_count,
    CASE 
        WHEN gs.genre_rank <= 3 THEN 'Top Genre'
        ELSE 'Other Genre'
    END AS genre_category
FROM 
    GenreSummary gs
ORDER BY 
    gs.movie_count DESC;

This SQL query consists of two main parts:

1. **Part 1**: A recursive common table expression (CTE) called `MovieHierarchy` is defined to create a hierarchy of linked movies up to three levels deep. This CTE is then used to gather actor statistics in `ActorStats`, including the number of movies an actor appeared in and a list of those movies. Then, `RoleCount` calculates the distinct roles for each actor. The final selection produces a list of actors with a ranking based on their movie count.

2. **Part 2**: It calculates the counts of movies by genre using `GenreCount` and summarizes them into `GenreSummary`. This section uses ranking to classify genres as 'Top Genre' if they fall within the top three by movie count.

This elaborate query showcases various SQL constructs, including CTEs, window functions, aggregates, joins, and also incorporates NULL handling via the `COALESCE` function.
