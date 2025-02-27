WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_within_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
FilteredActors AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
),
MoviesWithActors AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        fa.name AS actor_name,
        fa.movie_count
    FROM 
        RankedMovies rm
    JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    JOIN 
        FilteredActors fa ON ci.person_id = fa.person_id
)
SELECT 
    mw.movie_id,
    mw.title,
    mw.production_year,
    mw.actor_name,
    mw.movie_count,
    CASE 
        WHEN mw.movie_count > 10 THEN 'Prolific Actor'
        WHEN mw.movie_count BETWEEN 6 AND 10 THEN 'Frequent Actor'
        ELSE 'Occasional Actor'
    END AS actor_type,
    COALESCE((SELECT STRING_AGG(note, ', ') 
              FROM movie_info mi 
              WHERE mi.movie_id = mw.movie_id 
              AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Award')), 
             'No Awards') AS award_notes
FROM 
    MoviesWithActors mw
WHERE 
    mw.production_year BETWEEN 2000 AND 2020
ORDER BY 
    mw.production_year DESC, 
    mw.rank_within_year, 
    mw.actor_name ASC;
