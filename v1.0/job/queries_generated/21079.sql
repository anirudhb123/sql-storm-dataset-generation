WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id ASC) AS movie_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.movie_rank
    FROM 
        RankedMovies rm
    WHERE 
        rm.movie_rank <= 5
),
MovieCast AS (
    SELECT 
        cm.movie_id,
        GROUP_CONCAT(CONCAT(a.name, ' as ', rt.role)) AS cast_roles
    FROM 
        cast_info cm
    JOIN 
        aka_name a ON cm.person_id = a.person_id
    JOIN 
        role_type rt ON cm.role_id = rt.id
    GROUP BY 
        cm.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        COALESCE(mo.cast_roles, 'No Cast') AS cast_roles,
        COALESCE(mc.companies, 'No Companies') AS companies
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieCast mo ON tm.movie_id = mo.movie_id
    LEFT JOIN 
        MovieCompanies mc ON tm.movie_id = mc.movie_id
)

SELECT 
    md.title,
    md.production_year,
    md.cast_roles,
    md.companies,
    (SELECT COUNT(*) 
     FROM movie_keyword mk 
     WHERE mk.movie_id = md.movie_id) AS keyword_count,
    CASE
        WHEN md.cast_roles IS NULL OR md.cast_roles = 'No Cast' THEN 'Unknown'
        ELSE 'Known'
    END AS cast_status
FROM 
    MovieDetails md
WHERE 
    md.production_year = (SELECT MAX(production_year) FROM TopMovies)
ORDER BY 
    md.production_year DESC, 
    md.title;

This query contains various SQL concepts such as Common Table Expressions (CTEs) for organizing the data and creating intermediate results, window functions for calculations on movie rankings and counts, and aggregate functions to handle the collection of cast names and company names. It also includes CASE statements for assessing the cast status, correlated subqueries for counting keywords associated with each movie, and a selection of movies based on their production year and other conditions. Additionally, outer joins are used to ensure that even movies without associated cast or company names are included in the final results.
