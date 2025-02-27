WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
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
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    cd.company_name,
    cd.company_type,
    mk.keywords,
    CASE 
        WHEN mk.keywords IS NULL THEN 'No Keywords'
        ELSE mk.keywords
    END AS processed_keywords
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyDetails cd ON tm.movie_id = cd.movie_id
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
ORDER BY 
    tm.production_year DESC, 
    cast_count DESC;
