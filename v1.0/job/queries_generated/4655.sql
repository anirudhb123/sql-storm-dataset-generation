WITH MovieStats AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        AVG(CASE WHEN at.production_year IS NOT NULL THEN 2023 - at.production_year ELSE NULL END) AS age_of_movie
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        at.id
),
GenreCount AS (
    SELECT 
        at.id AS movie_id,
        COUNT(DISTINCT mk.keyword_id) AS genre_count
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    GROUP BY 
        at.id
),
FinalStats AS (
    SELECT 
        ms.title,
        ms.production_year,
        ms.cast_count,
        ms.cast_names,
        ms.age_of_movie,
        COALESCE(gc.genre_count, 0) AS genre_count
    FROM 
        MovieStats ms
    LEFT JOIN 
        GenreCount gc ON ms.title = gc.movie_id
)
SELECT 
    title,
    production_year,
    cast_count,
    cast_names,
    age_of_movie,
    genre_count
FROM 
    FinalStats
WHERE 
    (age_of_movie > 10 AND genre_count > 2) OR cast_count > 5 
ORDER BY 
    production_year DESC, cast_count DESC;
