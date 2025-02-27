WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year, cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
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
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.cast_count,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(mc.company_count, 0) AS company_count,
    COALESCE(mc.company_names, 'No company') AS company_names
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    MovieCompanies mc ON tm.movie_id = mc.movie_id
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
