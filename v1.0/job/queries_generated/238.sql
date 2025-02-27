WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
SelectMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count,
        COALESCE(SUM(CASE WHEN mp.info_type_id = 1 THEN 1 ELSE 0 END), 0) AS genre_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info mp ON rm.title = mp.info
    WHERE 
        rm.rank <= 10
    GROUP BY 
        rm.title, rm.production_year, rm.cast_count
)
SELECT 
    sm.title,
    sm.production_year,
    sm.cast_count,
    sm.genre_count,
    CASE 
        WHEN sm.genre_count > 3 THEN 'Diverse Genre'
        ELSE 'Limited Genre'
    END AS genre_flexibility,
    (SELECT AVG(SUBSTRING(aka.name FROM '^[^ ]+')) 
     FROM aka_name aka 
     JOIN cast_info ci ON aka.person_id = ci.person_id 
     WHERE ci.movie_id IN (SELECT movie_id FROM cast_info WHERE person_role_id IS NOT NULL)) AS avg_first_name_length
FROM 
    SelectMovies sm
ORDER BY 
    sm.cast_count DESC, 
    sm.production_year DESC
LIMIT 20;
