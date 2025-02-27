WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.linked_movie_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        RANK() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rank_within_level,
        COUNT(*) OVER (PARTITION BY mh.level) AS total_movies_at_level
    FROM 
        MovieHierarchy mh
),
CastInfoWithRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ARRAY_AGG(DISTINCT rt.role ORDER BY rt.role) AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.level,
    rm.rank_within_level,
    rm.total_movies_at_level,
    COALESCE(ciwr.total_cast, 0) AS total_cast,
    COALESCE(ciwr.roles, ARRAY[]::text[]) AS roles
FROM 
    RankedMovies rm
LEFT JOIN 
    CastInfoWithRoles ciwr ON rm.movie_id = ciwr.movie_id
WHERE 
    rm.rank_within_level <= 5 
    AND rm.total_movies_at_level > 10
ORDER BY 
    rm.level, rm.rank_within_level;

This SQL query consists of several constructs:

1. **Recursive CTE (`MovieHierarchy`)**: This collects all linked movies recursively, building a hierarchy based on linked film IDs.

2. **Ranking and Counting Films (`RankedMovies`)**: This assigns ranks to movies by production year within each level of the hierarchy and counts the total number of movies at each level.

3. **Aggregated Cast Info (`CastInfoWithRoles`)**: This subquery calculates the total distinct cast and their roles for each movie.

4. **Main Query**: This combines all elements, using left joins and a WHERE clause with complex predicates to filter for the top-ranked movies at each hierarchy level, ensuring that only those levels with more than ten movies are considered. 

5. **COALESCE**: Used to replace NULLs with a default value for cast count and roles.

6. **Ordering**: Finally, the results are ordered by movie levels and their respective ranks.
