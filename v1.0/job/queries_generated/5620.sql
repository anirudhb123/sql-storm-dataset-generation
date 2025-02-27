WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        title t
    JOIN 
        aka_title at ON t.id = at.movie_id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.title, t.production_year
), 
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        cast_count,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        cast_count > 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    ARRAY_AGG(DISTINCT ak.name) AS aliases
FROM 
    TopMovies tm
JOIN 
    aka_name ak ON ak.person_id IN (
        SELECT person_id 
        FROM cast_info ci
        JOIN complete_cast cc ON ci.id = cc.subject_id
        WHERE cc.movie_id = tm.id
    )
GROUP BY 
    tm.title, tm.production_year, tm.cast_count
ORDER BY 
    tm.cast_count DESC
LIMIT 10;
