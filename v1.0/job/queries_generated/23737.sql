WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.movie_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.movie_id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        *
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5 -- Top 5 movies per production year
),
CompanyDetails AS (
    SELECT 
        m.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY co.country_code) AS company_rank
    FROM 
        movie_companies m
    JOIN 
        company_name co ON m.company_id = co.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
),
MovieCompanies AS (
    SELECT 
        td.title,
        td.production_year,
        cd.company_name,
        cd.company_type
    FROM 
        TopMovies td
    LEFT JOIN 
        CompanyDetails cd ON td.id = cd.movie_id AND cd.company_rank = 1 -- Only include the primary company
),
MovieKeywords AS (
    SELECT 
        t.title,
        string_agg(k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title
),
FinalMovies AS (
    SELECT 
        mc.title,
        mc.production_year,
        mc.company_name,
        mc.company_type,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        CASE 
            WHEN mc.company_type IS NULL THEN 'Independent'
            ELSE mc.company_type 
        END AS effective_company_type
    FROM 
        MovieCompanies mc
    LEFT JOIN 
        MovieKeywords mk ON mc.title = mk.title
)
SELECT 
    title,
    production_year,
    company_name,
    effective_company_type,
    keywords
FROM 
    FinalMovies
WHERE 
    production_year >= 2000
ORDER BY 
    production_year DESC, title ASC;
