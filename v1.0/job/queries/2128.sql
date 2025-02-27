WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rn
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count,
        CASE 
            WHEN rm.cast_count > (SELECT AVG(cast_count) FROM RankedMovies) THEN 'Above Average'
            ELSE 'Below Average'
        END AS cast_rating
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn <= 10
)
SELECT 
    fm.title,
    fm.production_year,
    fm.cast_count,
    fm.cast_rating,
    COALESCE(
        (SELECT STRING_AGG(name, ', ') 
         FROM aka_name an 
         JOIN cast_info ci ON an.person_id = ci.person_id 
         WHERE ci.movie_id IN (SELECT id FROM aka_title WHERE title = fm.title)), 
        'No Cast'
    ) AS cast_members
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC;
