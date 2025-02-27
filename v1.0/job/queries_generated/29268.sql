WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(mk.keyword) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title, 
        production_year,
        keyword_count,
        RANK() OVER (ORDER BY keyword_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.title,
    tm.production_year,
    a.name AS actor_name,
    COUNT(ci.person_id) AS actor_count,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
FROM 
    TopMovies tm
JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.title, tm.production_year, a.name
ORDER BY 
    tm.production_year DESC, actor_count DESC;
