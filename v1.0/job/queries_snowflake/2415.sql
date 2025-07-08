
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_in_year
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year >= 2000 
    GROUP BY 
        t.id, t.title, t.production_year
), 
TopMovies AS (
    SELECT 
        title_id, 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank_in_year <= 5
), 
MovieKeywords AS (
    SELECT 
        tm.title_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        TopMovies tm
    JOIN 
        movie_keyword mk ON tm.title_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        tm.title_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.country_code IS NOT NULL
)
SELECT 
    tm.title,
    tm.production_year,
    mk.keywords,
    COALESCE(ci.company_name, 'No company') AS company_name,
    COALESCE(ci.company_type, 'N/A') AS company_type,
    ROW_NUMBER() OVER (ORDER BY tm.production_year DESC) AS row_num
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.title_id = mk.title_id
LEFT JOIN 
    CompanyInfo ci ON tm.title_id = ci.movie_id
ORDER BY 
    tm.production_year DESC, 
    row_num;
