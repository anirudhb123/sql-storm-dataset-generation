WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.id) DESC) AS rank_by_cast
    FROM 
        title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast <= 5
),
CompanyMovies AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        cm.company_name,
        cm.company_type
    FROM 
        TopMovies tm
    LEFT JOIN 
        CompanyMovies cm ON tm.movie_id = cm.movie_id
),
KeywordCounts AS (
    SELECT 
        m.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.id
)
SELECT 
    md.title,
    md.production_year,
    md.company_name,
    md.company_type,
    COALESCE(kc.keyword_count, 0) AS total_keywords
FROM 
    MovieDetails md
LEFT JOIN 
    KeywordCounts kc ON md.movie_id = kc.movie_id
WHERE 
    md.company_type IS NOT NULL
AND 
    (md.production_year > 2000 OR md.production_year IS NULL)
ORDER BY 
    md.production_year ASC, total_keywords DESC;
