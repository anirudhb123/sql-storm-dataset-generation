
WITH MovieCounts AS (
    SELECT 
        mt.production_year,
        COUNT(*) AS total_movies,
        AVG(mc.nr_order) AS avg_cast_order
    FROM 
        aka_title mt
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    JOIN 
        cast_info mc ON cc.subject_id = mc.person_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.production_year
),
TopMovies AS (
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT mc.person_id) AS cast_count
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info mc ON cc.subject_id = mc.person_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
    HAVING 
        COUNT(DISTINCT mc.person_id) >= 5
)
SELECT 
    mv.title,
    mv.production_year,
    COALESCE(mv.cast_count, 0) AS cast_count,
    COALESCE(mc.total_movies, 0) AS total_movies,
    COALESCE(mc.avg_cast_order, 0) AS avg_cast_order,
    CASE 
        WHEN mv.production_year IS NOT NULL AND mc.total_movies > 0 
        THEN ROUND((CAST(mv.cast_count AS NUMERIC) / mc.total_movies) * 100, 2)
        ELSE NULL 
    END AS cast_percentage
FROM 
    TopMovies mv
LEFT JOIN 
    MovieCounts mc ON mv.production_year = mc.production_year
ORDER BY 
    mv.production_year DESC, 
    cast_percentage DESC NULLS LAST;
