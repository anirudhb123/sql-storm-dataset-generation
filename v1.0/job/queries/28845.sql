WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        a.name AS director_name,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_within_year
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        mc.company_type_id = (SELECT id FROM company_type WHERE kind='Director')
    GROUP BY 
        mt.id, mt.title, mt.production_year, a.name
), FilteredMovies AS (
    SELECT
        movie_id,
        movie_title,
        production_year,
        director_name,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank_within_year <= 5
)
SELECT 
    fm.movie_title,
    fm.production_year,
    fm.director_name,
    fm.cast_count,
    ki.keyword AS movie_keyword
FROM 
    FilteredMovies fm
LEFT JOIN 
    movie_keyword mk ON fm.movie_id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
ORDER BY 
    fm.production_year DESC, 
    fm.cast_count DESC;
