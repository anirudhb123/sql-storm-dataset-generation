WITH RankedMovies AS (
    SELECT 
        title.title AS movie_title,
        aka_title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS total_cast,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS cast_names
    FROM 
        title
    JOIN 
        aka_title ON title.id = aka_title.movie_id
    JOIN 
        cast_info ON aka_title.movie_id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    GROUP BY 
        title.title, aka_title.production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        total_cast,
        cast_names,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY total_cast DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.total_cast,
    tm.cast_names
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 5
ORDER BY 
    tm.production_year ASC, 
    tm.total_cast DESC;
