
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_count
    FROM 
        RankedMovies rm
    WHERE 
        rn <= 5
),
MoviesWithKeywords AS (
    SELECT 
        t.title,
        k.keyword
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    LISTAGG(mkw.keyword, ', ') WITHIN GROUP (ORDER BY mkw.keyword) AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    MoviesWithKeywords mkw ON tm.title = mkw.title
GROUP BY 
    tm.title, tm.production_year, tm.actor_count
ORDER BY 
    tm.production_year DESC, tm.actor_count DESC;
