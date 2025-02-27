
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS num_cast_members
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.num_cast_members,
        ROW_NUMBER() OVER (ORDER BY rm.num_cast_members DESC) AS rn
    FROM 
        RankedMovies rm
)

SELECT 
    tm.title,
    tm.production_year,
    tm.num_cast_members,
    COUNT(DISTINCT k.keyword) AS num_keywords
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON tm.title = (SELECT title FROM title WHERE id = mk.movie_id)
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    tm.rn <= 10
GROUP BY 
    tm.title, tm.production_year, tm.num_cast_members
ORDER BY 
    tm.num_cast_members DESC;
