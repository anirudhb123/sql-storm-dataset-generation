WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
), FilteredMovies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rn
    FROM 
        RankedMovies
    WHERE 
        production_year IS NOT NULL
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.keywords,
    rm.cast_count
FROM 
    FilteredMovies rm
WHERE 
    rm.rn <= 5
ORDER BY 
    rm.production_year ASC, 
    rm.cast_count DESC;

