WITH RankedMovies AS (
    SELECT 
        at.title, 
        at.production_year, 
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
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
CompanyDetails AS (
    SELECT 
        mc.movie_id, 
        cn.name AS company_name, 
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    tm.title, 
    tm.production_year, 
    cd.company_name,
    cd.company_type,
    CASE 
        WHEN cd.company_name IS NULL THEN 'Independent' 
        ELSE cd.company_name 
    END AS final_company_name,
    (SELECT 
        COUNT(DISTINCT ki.keyword_id) 
     FROM 
        movie_keyword ki 
     WHERE 
        ki.movie_id = tm.movie_id) AS keyword_count
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyDetails cd ON tm.movie_id = cd.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.title ASC;
