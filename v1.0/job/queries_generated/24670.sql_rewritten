WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
RecentMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_by_year <= 5
),
Actors AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        a.actor_count,
        COALESCE(a.actor_names, 'No actors') AS actor_names
    FROM 
        RecentMovies r
    LEFT JOIN 
        Actors a ON r.movie_id = a.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_count,
    md.actor_names,
    CASE 
        WHEN md.actor_count IS NULL THEN 'Zero Actors'
        WHEN md.actor_count < 5 THEN 'Fewer than 5 Actors'
        ELSE '5 or more Actors'
    END AS cast_evaluation
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC,
    md.title;