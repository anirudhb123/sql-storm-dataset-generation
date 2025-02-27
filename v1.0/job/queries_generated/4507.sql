WITH RankedMovies AS (
    SELECT 
        at.title, 
        at.production_year, 
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
FilteredMovies AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        rm.cast_count 
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
)
SELECT 
    f.title,
    f.production_year,
    f.cast_count,
    COALESCE(
        (SELECT STRING_AGG(ak.name, ', ') 
         FROM aka_name ak 
         JOIN cast_info c ON ak.person_id = c.person_id 
         WHERE c.movie_id IN (SELECT movie_id FROM complete_cast WHERE subject_id = (SELECT id FROM title WHERE title = f.title))
         GROUP BY c.movie_id
        ), 'No Cast') AS lead_cast
FROM 
    FilteredMovies f
ORDER BY 
    f.production_year DESC, 
    f.cast_count DESC;
