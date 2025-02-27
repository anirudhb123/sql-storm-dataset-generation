WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rn
    FROM 
        aka_title AS t
    LEFT JOIN 
        cast_info AS c ON t.id = c.movie_id
    GROUP BY 
        t.id
),
HighCastMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(mi.info, ', ') AS movie_notes
    FROM 
        HighCastMovies AS m
    LEFT JOIN 
        movie_info AS mi ON m.movie_id = mi.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    h.title,
    h.production_year,
    COALESCE(mi.movie_notes, 'No notes available') AS movie_notes,
    CASE 
        WHEN h.production_year < 2000 THEN 'Older Film'
        WHEN h.production_year BETWEEN 2000 AND 2020 THEN 'Modern Film'
        ELSE 'New Release'
    END AS film_category
FROM 
    HighCastMovies AS h
LEFT JOIN 
    MovieInfo AS mi ON h.movie_id = mi.movie_id
ORDER BY 
    h.production_year DESC, 
    h.title;
