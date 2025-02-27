WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(cc.movie_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(cc.movie_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
MoviesWithKeywords AS (
    SELECT 
        tm.title,
        tm.production_year,
        mk.keyword
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
)
SELECT 
    mwk.title,
    mwk.production_year,
    mwk.keyword,
    COALESCE(cn.name, 'Unknown') AS company_name,
    COUNT(DISTINCT ci.person_id) AS crew_count
FROM 
    MoviesWithKeywords mwk
LEFT JOIN 
    movie_companies mc ON mwk.title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    cast_info ci ON mwk.title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
GROUP BY 
    mwk.title, mwk.production_year, mwk.keyword, cn.name
HAVING 
    COUNT(DISTINCT ci.person_id) > 0
ORDER BY 
    mwk.production_year DESC, mwk.title;
