WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY LENGTH(title.title) DESC) AS rank_by_length,
        COUNT(DISTINCT movie_keyword.keyword_id) AS keyword_count
    FROM 
        title
    LEFT JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    GROUP BY 
        title.id, title.title, title.production_year
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword_count
    FROM 
        RankedMovies
    WHERE 
        rank_by_length <= 5
),
CastDetails AS (
    SELECT 
        cast_info.movie_id,
        COUNT(DISTINCT cast_info.person_id) AS total_cast,
        MAX(role_type.role) AS highest_role
    FROM 
        cast_info
    JOIN 
        role_type ON cast_info.role_id = role_type.id
    GROUP BY 
        cast_info.movie_id
),
MovieCompanyDetails AS (
    SELECT 
        movie_companies.movie_id,
        STRING_AGG(DISTINCT company_name.name, ', ') AS companies_involved
    FROM 
        movie_companies
    JOIN 
        company_name ON movie_companies.company_id = company_name.id
    GROUP BY 
        movie_companies.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    fm.keyword_count,
    cd.total_cast,
    cd.highest_role,
    mcd.companies_involved
FROM 
    FilteredMovies fm
LEFT JOIN 
    CastDetails cd ON fm.movie_id = cd.movie_id
LEFT JOIN 
    MovieCompanyDetails mcd ON fm.movie_id = mcd.movie_id
WHERE 
    fm.production_year IS NOT NULL 
    AND (cd.highest_role IS NOT NULL OR cd.total_cast > 3)
ORDER BY 
    fm.production_year DESC,
    fm.keyword_count DESC
LIMIT 10;