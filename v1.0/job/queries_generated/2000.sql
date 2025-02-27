WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) as rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
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
        tm.movie_id,
        tm.title,
        tm.production_year,
        GROUP_CONCAT(DISTINCT p.name ORDER BY p.name) AS actors,
        GROUP_CONCAT(DISTINCT c.name ORDER BY c.name) AS companies
    FROM 
        TopMovies tm
    LEFT JOIN 
        complete_cast cc ON tm.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name p ON cc.subject_id = p.person_id
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
),
MoviesWithInfo AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.actors,
        md.companies,
        COALESCE(mi.info, 'No additional info') AS additional_info
    FROM 
        MovieDetails md
    LEFT JOIN 
        movie_info mi ON md.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot Summary')
)
SELECT 
    mw.movie_id,
    mw.title,
    mw.production_year,
    mw.actors,
    mw.companies,
    mw.additional_info,
    CASE 
        WHEN mw.production_year < 1990 THEN 'Classic'
        WHEN mw.production_year BETWEEN 1990 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_period
FROM 
    MoviesWithInfo mw
WHERE 
    mw.actors IS NOT NULL
  AND 
    mw.companies IS NOT NULL
ORDER BY 
    mw.production_year DESC;
