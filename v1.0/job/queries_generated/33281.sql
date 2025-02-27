WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL  -- top-level movies

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        aka_title mt
    INNER JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rn
    FROM 
        MovieHierarchy mh
),
ActorAwards AS (
    SELECT 
        ci.movie_id,
        a.id AS actor_id,
        a.name,
        COUNT(DISTINCT pi.info_id) AS award_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        person_info pi ON pi.person_id = a.person_id AND pi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Award')
    GROUP BY 
        ci.movie_id, a.id, a.name
)
SELECT 
    rm.title AS movie_title,
    rm.production_year,
    rm.level,
    a.name AS actor_name,
    COALESCE(a.award_count, 0) AS award_count
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorAwards a ON rm.movie_id = a.movie_id
WHERE 
    rm.rn <= 3  -- Get top 3 most recent movies at each level
ORDER BY 
    rm.level, 
    rm.production_year DESC,
    award_count DESC;

### Explanation:
- **CTE MovieHierarchy**: This recursive CTE builds a hierarchy of movies where top-level movies (without episodes) are selected first, followed by episodes that reference those movies.
- **CTE RankedMovies**: This selects movies from the hierarchy and assigns a rank (`ROW_NUMBER()`) to each movie in its level based on the production year.
- **CTE ActorAwards**: This aggregates awards associated with actors in the movie, counting distinct awards through a join with the `person_info` table, conditionally filtering based on award information.
- **Main Query**: Combines the ranked movies and actor award counts, filtering to retrieve only the top 3 movies at each hierarchy level while ordering by production year and award counts. It makes use of `COALESCE` to handle potential `NULL` values for actors without awards.
