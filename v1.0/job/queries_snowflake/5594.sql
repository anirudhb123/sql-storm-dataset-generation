WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        km.keyword AS movie_keyword,
        COUNT(ci.person_id) AS cast_count
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword km ON mk.keyword_id = km.id
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.id = ci.movie_id
    GROUP BY 
        mt.title, mt.production_year, km.keyword
),
FilteredMovies AS (
    SELECT 
        title,
        production_year,
        movie_keyword,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        production_year BETWEEN 2000 AND 2020
)
SELECT 
    fm.title,
    fm.production_year,
    fm.movie_keyword,
    fm.cast_count,
    (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = (SELECT id FROM aka_title WHERE title = fm.title LIMIT 1)) AS company_count
FROM 
    FilteredMovies fm
ORDER BY 
    fm.cast_count DESC, 
    fm.production_year DESC
LIMIT 10;
