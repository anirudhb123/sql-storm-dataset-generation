
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(ci.id) AS cast_count,
        LISTAGG(aka.name, ', ') WITHIN GROUP (ORDER BY aka.name) AS cast_names,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.id) DESC) AS rank_by_cast_count
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name aka ON ci.person_id = aka.person_id
    WHERE 
        mt.production_year IS NOT NULL 
    GROUP BY 
        mt.id, mt.title, mt.production_year
),

FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.cast_names
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_by_cast_count <= 5
),

FinalOutput AS (
    SELECT
        fm.movie_id,
        fm.title,
        fm.production_year,
        fm.cast_count,
        CONCAT('Cast: ', fm.cast_names) AS detailed_cast_info
    FROM 
        FilteredMovies fm
)

SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.cast_count,
    f.detailed_cast_info
FROM 
    FinalOutput f
ORDER BY 
    f.production_year DESC, f.cast_count DESC;
