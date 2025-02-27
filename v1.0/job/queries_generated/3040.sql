WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER(PARTITION BY a.id ORDER BY COUNT(c.person_id) DESC) AS rn
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
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rn <= 10
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
MovieCompanies AS (
    SELECT 
        m.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies m
    JOIN 
        company_name co ON m.company_id = co.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(mc.company_name, 'Independent') AS production_company,
    COALESCE(mc.company_type, 'Not Specified') AS company_type
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    MovieCompanies mc ON tm.movie_id = mc.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
