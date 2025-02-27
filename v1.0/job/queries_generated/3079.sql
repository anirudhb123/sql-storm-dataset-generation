WITH MovieDetails AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id
), 
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        total_cast,
        cast_names,
        ROW_NUMBER() OVER (ORDER BY total_cast DESC) AS rn
    FROM 
        MovieDetails
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.total_cast,
    tm.cast_names,
    COALESCE(mi.info, 'N/A') AS additional_info
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info mi ON tm.movie_title = (SELECT title FROM aka_title WHERE id = tm.movie_title LIMIT 1)
WHERE 
    tm.rn <= 10
ORDER BY 
    tm.total_cast DESC;
