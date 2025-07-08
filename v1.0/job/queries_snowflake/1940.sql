
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title AS a
    LEFT JOIN 
        cast_info AS c ON a.id = c.movie_id
    GROUP BY 
        a.title, 
        a.production_year
), 
FilteredMovies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
), 
MovieGenres AS (
    SELECT 
        k.keyword AS genre,
        mt.id AS movie_id
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    JOIN 
        aka_title AS mt ON mk.movie_id = mt.id
)
SELECT 
    fm.title,
    fm.production_year,
    fm.cast_count,
    LISTAGG(DISTINCT mg.genre, ', ') WITHIN GROUP (ORDER BY mg.genre) AS genres
FROM 
    FilteredMovies AS fm
LEFT JOIN 
    MovieGenres AS mg ON mg.movie_id = (SELECT m.id FROM aka_title m WHERE m.title = fm.title AND m.production_year = fm.production_year LIMIT 1)
GROUP BY 
    fm.title, 
    fm.production_year, 
    fm.cast_count
ORDER BY 
    fm.production_year DESC, 
    fm.cast_count DESC;
