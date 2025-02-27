WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        at.title,
        k.keyword
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON at.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
MovieCompanies AS (
    SELECT 
        at.title,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        aka_title at
    LEFT JOIN 
        movie_companies mc ON at.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT mc.company_name || ' (' || mc.company_type || ')', '; ') AS companies
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.title = mk.title
LEFT JOIN 
    MovieCompanies mc ON tm.title = mc.title
GROUP BY 
    tm.title, tm.production_year, tm.cast_count
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
