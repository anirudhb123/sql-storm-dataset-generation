WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        m.title,
        k.keyword
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_keyword mk ON m.title = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
CompanyMovies AS (
    SELECT 
        m.title,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        aka_title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    km.title,
    STRING_AGG(DISTINCT km.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT cm.company_name || ':' || cm.company_type, '; ') AS companies
FROM 
    MovieKeywords km
LEFT JOIN 
    CompanyMovies cm ON km.title = cm.title
GROUP BY 
    km.title
ORDER BY 
    km.title;
