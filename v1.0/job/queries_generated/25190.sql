WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        a.id AS movie_id, 
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    GROUP BY 
        a.id
),
TopMovies AS (
    SELECT
        rm.title,
        rm.production_year,
        rm.keywords,
        rm.cast_count,
        RANK() OVER (ORDER BY rm.cast_count DESC) AS rnk
    FROM 
        RankedMovies rm
    WHERE 
        rm.production_year >= 2000
)

SELECT 
    tm.title, 
    tm.production_year, 
    tm.keywords, 
    tm.cast_count
FROM 
    TopMovies tm
WHERE 
    tm.rnk <= 10
ORDER BY 
    tm.cast_count DESC;
