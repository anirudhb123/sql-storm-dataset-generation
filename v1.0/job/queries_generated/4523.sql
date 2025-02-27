WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS movie_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
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
        movie_rank = 1
),
KeywordStats AS (
    SELECT 
        mt.movie_id,
        COUNT(mk.keyword_id) AS keyword_count,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(ks.keyword_count, 0) AS keyword_count,
    COALESCE(ks.keywords, 'No keywords') AS keywords,
    cn.name AS company_name
FROM 
    TopMovies tm
LEFT JOIN 
    KeywordStats ks ON tm.movie_id = ks.movie_id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    tm.production_year >= 2000
ORDER BY 
    tm.production_year DESC, tm.title;
