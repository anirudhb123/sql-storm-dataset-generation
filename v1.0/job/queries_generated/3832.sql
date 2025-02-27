WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS ranking
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        ranking <= 5
),
MovieKeywords AS (
    SELECT 
        m.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = m.title AND production_year = m.production_year)
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.title, m.production_year
),
CompanyInfo AS (
    SELECT 
        m.title,
        c.name AS company_name,
        ct.kind AS company_type,
        COALESCE(mi.info, 'No additional info') AS movie_info
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = (SELECT id FROM aka_title WHERE title = m.title AND production_year = m.production_year)
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = (SELECT id FROM aka_title WHERE title = m.title AND production_year = m.production_year) AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
)
SELECT 
    mk.title,
    mk.keywords,
    ci.company_name,
    ci.company_type,
    ci.movie_info
FROM 
    MovieKeywords mk
FULL OUTER JOIN 
    CompanyInfo ci ON mk.title = ci.title
WHERE 
    mk.keywords IS NOT NULL OR ci.company_name IS NOT NULL
ORDER BY 
    mk.title;
