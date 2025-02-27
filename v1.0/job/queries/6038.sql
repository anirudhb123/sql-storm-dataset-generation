WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
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
        rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
    STRING_AGG(DISTINCT kr.keyword, ', ') AS keywords
FROM 
    TopMovies tm
JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword kr ON mk.keyword_id = kr.id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year
ORDER BY 
    tm.production_year DESC, total_cast DESC;
