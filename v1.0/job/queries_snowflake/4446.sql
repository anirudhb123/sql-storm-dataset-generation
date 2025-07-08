
WITH RankedMovies AS (
    SELECT 
        title.title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY COUNT(DISTINCT cast_info.person_id) DESC) AS rank
    FROM 
        title
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    GROUP BY 
        title.id, title.title, title.production_year
), 
CompanyMovies AS (
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
MovieKeywords AS (
    SELECT 
        movie_keyword.movie_id,
        LISTAGG(DISTINCT keyword.keyword, ', ') AS keywords
    FROM 
        movie_keyword
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY 
        movie_keyword.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    COALESCE(cm.company_name, 'No Company') AS company_name,
    COALESCE(cm.company_type, 'Unknown Type') AS company_type,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyMovies cm ON rm.title = (SELECT title.title FROM title WHERE id = cm.movie_id)
LEFT JOIN 
    MovieKeywords mk ON rm.title = (SELECT title.title FROM title WHERE id = mk.movie_id)
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
