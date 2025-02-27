WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        a.id AS movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS akas
    FROM aka_title a
    LEFT JOIN cast_info c ON a.id = c.movie_id
    LEFT JOIN aka_name ak ON ak.id = c.person_id
    GROUP BY a.title, a.production_year, a.id
),

FilteredMovies AS (
    SELECT 
        movie_title,
        production_year,
        movie_id,
        cast_count,
        akas
    FROM RankedMovies
    WHERE production_year >= 2000
    AND cast_count > 5
),

KeywordMovies AS (
    SELECT 
        fm.movie_id,
        ARRAY_AGG(k.keyword) AS keywords
    FROM FilteredMovies fm
    LEFT JOIN movie_keyword mk ON fm.movie_id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY fm.movie_id
)

SELECT 
    fm.movie_title,
    fm.production_year,
    fm.cast_count,
    fm.akas,
    km.keywords
FROM FilteredMovies fm
LEFT JOIN KeywordMovies km ON fm.movie_id = km.movie_id
ORDER BY fm.production_year DESC, fm.cast_count DESC;
