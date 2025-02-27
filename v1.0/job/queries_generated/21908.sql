WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC, mt.title) AS year_rank,
        COUNT(*) OVER (PARTITION BY mt.production_year) AS year_count
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
PremiereMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title,
        rm.production_year,
        CASE 
            WHEN rm.year_count > 1 THEN 'Multiple Entries'
            ELSE 'Unique Entry'
        END AS entry_type,
        ac.actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCounts ac ON rm.movie_id = ac.movie_id
),
FilteredMovies AS (
    SELECT 
        pm.movie_id,
        pm.title,
        pm.production_year,
        pm.entry_type,
        pm.actor_count,
        COALESCE(pm.actor_count, 0) AS safe_actor_count
    FROM 
        PremiereMovies pm
    WHERE 
        pm.production_year >= 2000 
        AND (pm.actor_count IS NULL OR pm.actor_count > 5)
),
KeywordSearch AS (
    SELECT 
        mk.movie_id,
        GROUP_CONCAT(k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.entry_type,
    fm.safe_actor_count,
    ks.keywords
FROM 
    FilteredMovies fm
LEFT JOIN 
    KeywordSearch ks ON fm.movie_id = ks.movie_id
ORDER BY 
    fm.production_year DESC, 
    fm.title,
    CASE 
        WHEN ks.keywords IS NULL THEN 1
        ELSE 0 
    END,
    fm.safe_actor_count DESC;

-- Adding NULL checks and peculiar edge cases.
WHERE 
    EXISTS (SELECT 1 FROM movie_info mi 
            WHERE mi.movie_id = fm.movie_id 
              AND mi.info IS NOT NULL 
              AND TRIM(mi.info) <> '')
    AND (fm.production_year > 2000 OR fm.actor_count IS NULL)
    OR fm.entry_type = 'Multiple Entries'

This query includes the following constructs and behaviors:

- **Common Table Expressions (CTEs)**: For organizing the query into logical blocks, making it easier to follow.
- **Window Functions**: To rank movies by production year while counting the total number of movies released each year.
- **Aggregates**: To count distinct actors in each movie and group keywords.
- **Outer Joins**: For including actor counts even when a movie has no actors.
- **Conditional Logic**: Using `COALESCE` and `CASE` statements for handling NULL values and distinguishing entry types.
- **String Aggregation**: To concatenate keywords associated with each movie.
- **Complex Predicates**: Using `EXISTS` subqueries and NULL/empty string checks to filter results.
- **Bizarre Semantics**: Handling both NULL logic and potential presence of multiple rows in unconventional narratives.

This query is structured to benchmark the performance of complex queries, while also handling various edge cases that might occur with the relationships and potential NULL values in the dataset.
