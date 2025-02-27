WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS rank_per_year
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
        AND mt.production_year IS NOT NULL
),
Actors AS (
    SELECT 
        ak.person_id,
        ak.name,
        COUNT(DISTINCT c.movie_id) AS total_movies,
        SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END) AS acting_roles
    FROM 
        aka_name ak
    LEFT JOIN 
        cast_info c ON ak.person_id = c.person_id
    GROUP BY 
        ak.person_id, ak.name
),
MoviesWithActors AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ak.name AS actor_name,
        ak.total_movies,
        ak.acting_roles
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        rm.rank_per_year <= 5 -- top 5 movies per year
)
SELECT 
    mw.movie_id,
    mw.title,
    mw.production_year,
    mw.actor_name,
    COALESCE(mw.total_movies, 0) AS total_movies,
    COALESCE(mw.acting_roles, 0) AS acting_roles,
    CASE 
        WHEN mw.total_movies IS NULL THEN 'No Movies'
        WHEN mw.acting_roles = 0 THEN 'Not an Actor'
        ELSE 'Active Actor'
    END AS actor_status
FROM 
    MoviesWithActors mw
FULL OUTER JOIN 
    (SELECT 
         movie_id, COUNT(*) AS related_movies
     FROM 
         movie_link
     GROUP BY 
         movie_id) ml ON mw.movie_id = ml.movie_id
WHERE 
    COALESCE(ml.related_movies, 0) > 2
ORDER BY 
    mw.production_year DESC, mw.title ASC
LIMIT 100;

### Explanation of Query Components:
1. **Common Table Expressions (CTEs)**:
   - `RankedMovies`: Ranks movies based on their production year and title, limiting the selection to movies categorized as 'movie' from `kind_type`.
   - `Actors`: Aggregates actors' total movies and acting roles from `aka_name` and `cast_info`, showcasing the versatility of CTEs in handling aggregated data.

2. **Join Operations**:
   - Uses `FULL OUTER JOIN` to account for all movies and linked movies, even if some do not have associated actor data.

3. **Window Functions**:
   - Adds `ROW_NUMBER()` to produce a rank for top movies each year.

4. **Conditional Logic**:
   - Applies `CASE` statement to classify actors based on their roles and movie counts, demonstrating complex conditional structures.

5. **NULL Handling**:
   - Utilizes `COALESCE` to replace NULLs with meaningful substitutes, both for total movie counts and actor status.

6. **Predicate Expressions**:
   - Incorporates a filter to focus on only those movies with a significant relationship to other films (`related_movies > 2`).

7. **Sorting and Limiting**:
   - Orders results by production year and title, capped at 100 results.

This query encompasses a complex interaction of SQL features designed for performance benchmarking and practical dataset manipulation.
