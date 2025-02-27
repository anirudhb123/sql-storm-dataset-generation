WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_within_year
    FROM 
        aka_title t
        LEFT JOIN cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actor_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_within_year <= 5
),
CompaniesWithMovies AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(cn.name) AS companies
    FROM 
        movie_companies mc
        JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.actor_count,
        cwm.companies
    FROM 
        TopMovies tm
        LEFT JOIN CompaniesWithMovies cwm ON tm.movie_id = cwm.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.actor_count,
    COALESCE(md.companies, 'Unknown') AS companies
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.actor_count DESC;
