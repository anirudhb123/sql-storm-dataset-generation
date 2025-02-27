WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year > 2000
), MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(SUM(CASE WHEN ci.role_id IS NULL THEN 1 ELSE 0 END), 0) AS null_roles_count,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
), CompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.null_roles_count,
    md.total_cast,
    md.keyword_count,
    COALESCE(ci.company_count, 0) AS company_count,
    COALESCE(ci.company_names, 'None') AS company_names
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyInfo ci ON md.movie_id = ci.movie_id
WHERE 
    md.total_cast > 5
ORDER BY 
    md.production_year DESC,
    md.title ASC
FETCH FIRST 50 ROWS ONLY;
