
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023 
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieGenres AS (
    SELECT 
        mt.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS genres
    FROM 
        movie_keyword mt
    LEFT JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.cast_count,
        mg.genres
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieGenres mg ON rm.movie_id = mg.movie_id
    WHERE 
        rm.rank <= 5
)
SELECT 
    tm.title,
    tm.cast_count,
    COALESCE(tm.genres, 'No Genre') AS genres,
    (SELECT AVG(cast_count) FROM RankedMovies) AS average_cast_count
FROM 
    TopMovies tm
ORDER BY 
    tm.cast_count DESC;
