
WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title at
    JOIN 
        cast_info c ON at.id = c.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
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
CompanyTitles AS (
    SELECT 
        mn.name AS company_name,
        at.title,
        at.production_year
    FROM 
        movie_companies mc
    JOIN 
        company_name mn ON mc.company_id = mn.id
    JOIN 
        aka_title at ON mc.movie_id = at.id
    WHERE 
        mn.country_code IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        at.title,
        k.keyword
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    tm.title,
    tm.production_year,
    COUNT(DISTINCT ct.company_name) AS company_count,
    LISTAGG(DISTINCT mk.keyword, ', ') WITHIN GROUP (ORDER BY mk.keyword) AS keywords,
    CASE 
        WHEN COUNT(DISTINCT ct.company_name) > 0 THEN TRUE 
        ELSE FALSE 
    END AS has_company
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyTitles ct ON tm.title = ct.title AND tm.production_year = ct.production_year
LEFT JOIN 
    MovieKeywords mk ON tm.title = mk.title
GROUP BY 
    tm.title, tm.production_year
ORDER BY 
    tm.production_year DESC, 
    COUNT(DISTINCT ct.company_name) DESC;
