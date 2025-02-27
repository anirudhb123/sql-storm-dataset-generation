
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        COUNT(ci.id) AS cast_count
    FROM 
        aka_title t
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
        production_year, 
        cast_count,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.cast_count
ORDER BY 
    tm.cast_count DESC;
