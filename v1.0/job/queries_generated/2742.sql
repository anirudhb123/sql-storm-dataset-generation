WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank_year,
        AVG(mo.rating) OVER (PARTITION BY a.movie_id) AS avg_rating
    FROM 
        aka_title a
    LEFT JOIN 
        movie_info mo ON a.id = mo.movie_id AND mo.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    WHERE 
        a.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        avg_rating
    FROM 
        RankedMovies
    WHERE 
        rank_year <= 5
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.avg_rating,
    COALESCE(cd.cast_count, 0) AS total_cast
FROM 
    TopMovies tm
LEFT JOIN 
    CastDetails cd ON tm.title = (SELECT t.title FROM aka_title t WHERE t.id = cd.movie_id)
ORDER BY 
    tm.avg_rating DESC, 
    tm.production_year DESC;
