WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
),
GenreCounts AS (
    SELECT 
        m.movie_id, 
        COUNT(DISTINCT k.id) AS genre_count
    FROM 
        RankedMovies m
    JOIN 
        movie_keyword kw ON m.movie_id = kw.movie_id
    JOIN 
        keyword k ON kw.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        rm.cast_names,
        gc.genre_count
    FROM 
        RankedMovies rm
    JOIN 
        GenreCounts gc ON rm.movie_id = gc.movie_id
    WHERE 
        rm.cast_count > 5 AND gc.genre_count > 2
    ORDER BY 
        rm.cast_count DESC, rm.production_year ASC
    LIMIT 10
)
SELECT 
    tm.movie_id,
    tm.movie_title,
    tm.production_year,
    tm.cast_count,
    tm.cast_names
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC;
