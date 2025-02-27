WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
), 
ActorStatistics AS (
    SELECT 
        a.person_id,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        SUM(ci.nr_order) AS total_order
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id
), 
ActorMovies AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT m.id) AS movies_with_keyword_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        movie_keyword mk ON ci.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword LIKE '%action%'
    GROUP BY 
        a.person_id
)
SELECT 
    rm.title AS movie_title,
    rm.production_year,
    ASR.actor_names,
    ASR.movie_count AS actor_movie_count,
    COALESCE(AM.movies_with_keyword_count, 0) AS action_movies_count,
    CASE 
        WHEN rm.total_movies > 5 THEN 'Popular'
        ELSE 'Independent'
    END AS movie_type
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorStatistics ASR ON ASR.movie_count >= 1 AND ASR.person_id IN (
        SELECT person_id FROM cast_info WHERE movie_id = rm.title_id
    )
LEFT JOIN 
    ActorMovies AM ON AM.person_id = ASR.person_id 
ORDER BY 
    rm.production_year DESC, 
    movie_title

This SQL query performs several complex operations:

1. **CTEs (Common Table Expressions)**:
    - `RankedMovies`: ranks movies within each production year and counts total movies per year.
    - `ActorStatistics`: aggregates actor information to get their names and the count of movies they appeared in, summing the order in which they appeared.
    - `ActorMovies`: counts movies associated with the keyword 'action' for each actor.

2. **Outer Joins**: The final query uses left joins to combine results from the ranked movies, actor statistics, and actor movies without dropping movies with no actor data.

3. **Window Functions**: The `ROW_NUMBER()` and `COUNT()` window functions are used to rank the titles and aggregate counts which are essential for analytics.

4. **String Aggregation**: The `STRING_AGG` function is employed to concatenate actor names into a single string for easy reading.

5. **NULL Logic**: The usage of `COALESCE` handles cases where there may not be action movies associated with an actor.

6. **Complicated Predicates**: The join condition for linking actors to movies is dynamically handled through a subquery.

7. **CASE Statements**: To classify movies as 'Popular' or 'Independent' based on the number of films released in that year.

This query serves a benchmarking purpose, testing various SQL constructs and performance implications across the Join Order Benchmark schema.
