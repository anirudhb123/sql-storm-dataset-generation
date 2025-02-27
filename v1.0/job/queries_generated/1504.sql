WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        COUNT(ci.person_id) AS num_cast,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.title, at.production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        num_cast,
        rank
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
    INNER JOIN 
        company_name cn ON mc.company_id = cn.id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    tm.movie_title,
    tm.num_cast,
    cd.company_name,
    cd.company_type
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyDetails cd ON tm.movie_id = cd.movie_id
ORDER BY 
    tm.num_cast DESC, tm.movie_title;

WITH MovieYearInfo AS (
    SELECT 
        title,
        production_year,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        title, production_year
)
SELECT 
    *
FROM 
    MovieYearInfo
WHERE 
    keywords IS NOT NULL
ORDER BY 
    production_year DESC;
