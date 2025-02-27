WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.title, 
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
ActorsInTopMovies AS (
    SELECT 
        a.name,
        a.person_id,
        tm.title
    FROM 
        aka_name a
    INNER JOIN 
        cast_info ci ON a.person_id = ci.person_id
    INNER JOIN 
        complete_cast cc ON ci.movie_id = cc.movie_id
    INNER JOIN 
        TopMovies tm ON cc.movie_id = (SELECT cc2.movie_id FROM complete_cast cc2 WHERE cc2.id = cc.id)
)
SELECT 
    a.name,
    tm.title,
    COUNT(DISTINCT tt.id) AS movie_count,
    STRING_AGG(DISTINCT tt.title, ', ') AS other_movies
FROM 
    ActorsInTopMovies a
JOIN 
    aka_title tt ON tt.id IN (SELECT ci.movie_id FROM cast_info ci WHERE ci.person_id = a.person_id)
LEFT JOIN 
    TopMovies tm ON tm.title = a.title
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name, tm.title
HAVING 
    COUNT(DISTINCT tt.id) > 1
ORDER BY 
    movie_count DESC, a.name;
