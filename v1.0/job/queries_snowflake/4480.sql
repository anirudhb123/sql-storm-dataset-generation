WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
HighRatedMovies AS (
    SELECT 
        m.movie_id,
        COUNT(k.id) AS keyword_count
    FROM 
        movie_keyword k
    JOIN 
        RankedMovies m ON k.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
    HAVING 
        COUNT(k.id) > 5
),
CompleteCasting AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS total_cast
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(c.total_cast, 0) AS total_cast,
    COALESCE(k.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN COALESCE(c.total_cast, 0) > 20 THEN 'Large Cast'
        WHEN COALESCE(c.total_cast, 0) BETWEEN 10 AND 20 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM 
    RankedMovies m
LEFT JOIN 
    CompleteCasting c ON m.movie_id = c.movie_id
LEFT JOIN 
    HighRatedMovies k ON m.movie_id = k.movie_id
WHERE 
    m.rn <= 10
ORDER BY 
    m.production_year DESC, m.title;
