WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        RANK() OVER (PARTITION BY title.production_year ORDER BY COUNT(cast_info.person_id) DESC) AS movie_rank
    FROM 
        title
    LEFT JOIN 
        cast_info ON title.id = cast_info.movie_id
    GROUP BY 
        title.id
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        movie_rank <= 5
),
CompanyDetails AS (
    SELECT 
        movie_companies.movie_id,
        company_name.name AS company_name,
        company_type.kind AS company_type
    FROM 
        movie_companies
    JOIN 
        company_name ON movie_companies.company_id = company_name.id
    JOIN 
        company_type ON movie_companies.company_type_id = company_type.id
),
KeywordCounts AS (
    SELECT 
        movie_keyword.movie_id,
        COUNT(movie_keyword.keyword_id) AS keyword_count
    FROM 
        movie_keyword
    GROUP BY 
        movie_keyword.movie_id
),
FinalResult AS (
    SELECT
        fm.movie_id,
        fm.title,
        fm.production_year,
        COALESCE(cd.company_name, 'Unknown Company') AS production_company,
        COALESCE(kc.keyword_count, 0) AS keyword_count
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        CompanyDetails cd ON fm.movie_id = cd.movie_id
    LEFT JOIN 
        KeywordCounts kc ON fm.movie_id = kc.movie_id
    WHERE
        (fm.production_year >= 2000 AND fm.production_year < 2023)
        OR (kc.keyword_count > 5)
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.production_company,
    fr.keyword_count
FROM 
    FinalResult fr
WHERE 
    fr.keyword_count IS NOT NULL
ORDER BY 
    fr.production_year DESC, fr.keyword_count DESC
LIMIT 10;
