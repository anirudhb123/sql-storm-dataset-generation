WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 10
),
GenderDistribution AS (
    SELECT 
        CASE 
            WHEN n.gender IS NULL THEN 'Unknown'
            ELSE n.gender 
        END AS gender, 
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        cast_info c
    JOIN 
        name n ON c.person_id = n.id
    GROUP BY 
        gender
)
SELECT 
    tm.title, 
    tm.production_year, 
    gd.gender, 
    gd.total_cast
FROM 
    TopMovies tm
JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
LEFT JOIN 
    GenderDistribution gd ON gd.total_cast > 0
WHERE 
    EXISTS (
        SELECT 1 
        FROM movie_keyword mk
        WHERE mk.movie_id = tm.movie_id AND mk.keyword_id IN (
            SELECT id FROM keyword WHERE keyword LIKE '%action%'
        )
    )
ORDER BY 
    tm.production_year DESC, 
    gd.total_cast DESC;
