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
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn <= 5
),
AdditionalInfo AS (
    SELECT 
        cm.movie_id,
        STRING_AGG(DISTINCT cname.name, ', ') AS company_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_companies cm
    LEFT JOIN 
        company_name cname ON cm.company_id = cname.id
    LEFT JOIN 
        movie_keyword mk ON cm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        cm.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(ai.company_names, 'No Companies') AS company_names,
    COALESCE(ai.keywords, 'No Keywords') AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    AdditionalInfo ai ON tm.movie_id = ai.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.title ASC;
