WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank_within_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL 
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank_within_year <= 3
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        COALESCE(GROUP_CONCAT(DISTINCT an.name ORDER BY an.name), 'No Actors') AS actors,
        COALESCE(GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name), 'No Companies') AS companies
    FROM 
        TopMovies tm
    LEFT JOIN 
        complete_cast cc ON tm.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name an ON cc.subject_id = an.person_id 
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
)
SELECT 
    title,
    production_year,
    actors,
    companies,
    CASE 
        WHEN production_year IS NULL THEN 'Unknown Year'
        WHEN production_year < 2000 THEN 'Classic'
        ELSE 'Modern'
    END AS era
FROM 
    MovieDetails
ORDER BY 
    production_year DESC, title;
