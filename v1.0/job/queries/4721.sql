WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM cast('2024-10-01' as date)) - t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopRankedMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
),
MovieDetails AS (
    SELECT 
        t.movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM 
        TopRankedMovies t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.movie_id, t.title, t.production_year
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_count,
    CASE 
        WHEN md.actor_count > 0 THEN md.actors 
        ELSE 'No actors available'
    END AS actors_list
FROM 
    MovieDetails md
WHERE 
    md.actor_count IS NOT NULL
ORDER BY 
    md.production_year DESC, md.actor_count DESC;