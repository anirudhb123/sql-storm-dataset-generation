WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank_within_year,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies_in_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        rm.*,
        CASE 
            WHEN total_movies_in_year > 5 THEN 'Popular Year'
            ELSE 'Less Popular Year'
        END AS year_category
    FROM 
        RankedMovies rm
    WHERE 
        rank_within_year <= 10
),
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT ak.person_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    GROUP BY 
        c.movie_id
),
MoviesWithActors AS (
    SELECT 
        fm.*,
        ac.actor_count
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        ActorCounts ac ON fm.movie_id = ac.movie_id
),
FinalOutput AS (
    SELECT 
        mw.title,
        mw.production_year,
        mw.year_category,
        COALESCE(mw.actor_count, 0) AS actor_count,
        CASE 
            WHEN mw.actor_count IS NULL THEN 'No Actors'
            WHEN mw.actor_count = 0 THEN 'No Actors'
            ELSE 'Has Actors'
        END AS actor_status
    FROM 
        MoviesWithActors mw
)
SELECT 
    title,
    production_year,
    year_category,
    actor_count,
    actor_status,
    CONCAT('Movie: ', title, ' (', production_year, ') - ', 
           actor_status, 
           ' with ', actor_count, ' actors') AS output_description
FROM 
    FinalOutput
WHERE 
    (year_category = 'Popular Year' AND actor_count > 5)
    OR (year_category = 'Less Popular Year' AND actor_count IS NULL)
ORDER BY 
    production_year DESC, title;
