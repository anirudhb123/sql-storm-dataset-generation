WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        DENSE_RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    JOIN 
        complete_cast cc ON cc.movie_id = at.id
    JOIN 
        cast_info ci ON ci.movie_id = at.id
    GROUP BY 
        at.title, at.production_year
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
        at.title,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON mk.movie_id = at.id
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        at.title
),
MovieCompanies AS (
    SELECT 
        at.title,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        aka_title at
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = at.id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    LEFT JOIN 
        company_type ct ON ct.id = mc.company_type_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(mc.company_name, 'Unknown company') AS production_company,
    COALESCE(mc.company_type, 'Unknown type') AS company_type,
    CASE 
        WHEN tm.production_year IS NULL THEN 'Year Not Available'
        WHEN tm.production_year < 2000 THEN 'Classic'
        ELSE 'Modern'
    END AS era
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON mk.title = tm.title
LEFT JOIN 
    MovieCompanies mc ON mc.title = tm.title
ORDER BY 
    tm.production_year DESC, 
    tm.title;
