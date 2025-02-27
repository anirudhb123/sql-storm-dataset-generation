WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.year_rank <= 5
),
MovieCast AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM 
        TopMovies m
    JOIN 
        cast_info c ON m.movie_id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        m.movie_id
),
ActorInfo AS (
    SELECT 
        c.person_id,
        COUNT(*) AS movie_count,
        STRING_AGG(DISTINCT a.name, ', ') AS names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.person_id
    HAVING 
        COUNT(*) > 1
),
FinalEvaluation AS (
    SELECT 
        mc.movie_id,
        mc.title,
        mc.actor_count,
        ai.movie_count,
        ai.names
    FROM 
        MovieCast mc
    LEFT JOIN 
        ActorInfo ai ON mc.actor_count = ai.movie_count
)
SELECT 
    fe.movie_id, 
    fe.title, 
    fe.actor_count,
    COALESCE(fe.movie_count, 0) AS movie_count,
    CASE 
        WHEN fe.movie_count IS NULL THEN 'No actor with multiple movies'
        ELSE fe.names
    END AS prominent_actors
FROM 
    FinalEvaluation fe
WHERE 
    fe.actor_count > 1
ORDER BY 
    fe.actor_count DESC, 
    fe.title COLLATE "C" ASC
LIMIT 10;

-- Additional statistics can be involved here for in-depth performance analysis.

### Explanation:
1. The first CTE (`RankedMovies`) ranks movies per production year.
2. The second CTE (`TopMovies`) filters the top 5 movies from each year.
3. The `MovieCast` CTE gathers data on the number of distinct actors for the top movies and aggregates their names.
4. The `ActorInfo` CTE identifies actors appearing in multiple movies and summarizes their names.
5. The final selection in `FinalEvaluation` combines both CTEs to form a comprehensive view of movie performances and actor involvement.
6. The resulting output orders the movies by the number of actors and includes bizarre NULL handling with a descriptive case statement. The query emphasizes performance through the use of ranking, aggregation, and multiple joins.
