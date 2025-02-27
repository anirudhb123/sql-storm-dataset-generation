WITH RankedMovies AS (
    SELECT 
        a.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank,
        COUNT(m.id) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title a
    JOIN 
        title t ON a.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        rank,
        total_movies
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
CastDetails AS (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT p.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    GROUP BY 
        c.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.rank,
    tm.total_movies,
    COALESCE(cd.cast_names, 'No cast information available') AS cast_details
FROM 
    TopMovies tm
LEFT JOIN 
    CastDetails cd ON tm.title = cd.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.rank;
