WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS title_count
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorNames AS (
    SELECT 
        ak.person_id,
        STRING_AGG(ak.name, ', ') AS actor_names
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.person_id
),
MoviesWithActors AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        an.actor_names
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    LEFT JOIN 
        ActorNames an ON ci.person_id = an.person_id
)
SELECT 
    m.title,
    m.production_year,
    CASE 
        WHEN m.title_count > 1 THEN 'Multiple Titles'
        ELSE 'Sole Title'
    END AS title_type,
    m.actor_names,
    COALESCE(m.production_year, 0) AS production_year_null_check
FROM 
    MoviesWithActors m
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM movie_keyword mk 
        WHERE mk.movie_id = m.movie_id 
        AND mk.keyword_id IN (
            SELECT id 
            FROM keyword 
            WHERE keyword LIKE '%bizarre%'
        )
    )
    AND (m.production_year IS NOT NULL OR m.actor_names IS NOT NULL)
ORDER BY 
    m.production_year DESC, 
    m.title ASC
LIMIT 50;

### Explanation of Query Constructs:
1. **CTEs**: Utilizes Common Table Expressions (CTEs) to structure the query in stages, including calculations for ranking movies and aggregating actor names.
2. **Window Functions**: Incorporates `ROW_NUMBER()` and `COUNT()` to create a ranking of movies based on their titles within each production year.
3. **String Aggregation**: Uses `STRING_AGG` to concatenate actor names into a single field.
4. **Outer Joins**: Applies left joins to retrieve actor names even if a movie does not have cast information.
5. **Correlated Subquery**: Uses a subquery in the `NOT EXISTS` clause to filter out movies with specific keywords.
6. **Complicated Predicate**: Includes a condition to handle NULL checks and gives alternative outputs based on the presence of actor names and production years.
7. **NULL Logic**: Utilizes `COALESCE` to provide a default value for NULL years.

This query is designed for performance benchmarking and efficiently captures complex relationships across the schema tables while addressing corner cases in data presence.
