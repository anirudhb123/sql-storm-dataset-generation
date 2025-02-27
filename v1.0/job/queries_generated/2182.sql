WITH RankedMovies AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, a.name) AS rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        rm.actor_name,
        rm.movie_title,
        rm.production_year,
        COALESCE(mi.info, 'No info available') AS movie_info,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info mi ON rm.movie_title = mi.info
    LEFT JOIN 
        movie_companies mc ON rm.movie_title = mc.movie_id
    GROUP BY 
        rm.actor_name, rm.movie_title, rm.production_year, mi.info
),
FilteredMovies AS (
    SELECT 
        actor_name,
        movie_title,
        production_year,
        movie_info,
        company_count
    FROM 
        MovieDetails
    WHERE 
        production_year >= 2000 AND company_count > 2
)
SELECT 
    actor_name,
    movie_title,
    production_year,
    movie_info,
    company_count
FROM 
    FilteredMovies
ORDER BY 
    production_year DESC, actor_name;
