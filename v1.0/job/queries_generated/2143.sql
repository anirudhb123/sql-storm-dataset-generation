WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
MovieKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.movie_id
    GROUP BY 
        mt.movie_id
),
MovieCountryCompanies AS (
    SELECT 
        at.title,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        aka_title at
    JOIN 
        movie_companies mc ON at.movie_id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        cn.country_code IS NOT NULL
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(cn.company_name, 'No companies') AS company_name,
    COALESCE(ct.company_type, 'No type') AS company_type
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.title = mk.movie_id
LEFT JOIN 
    MovieCountryCompanies cn ON tm.title = cn.title
ORDER BY 
    tm.production_year DESC, tm.actor_count DESC;
