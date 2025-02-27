WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
HighCastMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.cast_count > 5
),
Directors AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS director_count
    FROM 
        cast_info c
    WHERE 
        c.person_role_id IN (SELECT id FROM role_type WHERE role = 'director')
    GROUP BY 
        c.movie_id
)
SELECT 
    hcm.title,
    hcm.production_year,
    COALESCE(dc.director_count, 0) AS director_count,
    hcm.cast_count,
    CASE 
        WHEN hcm.production_year < 2000 THEN 'Classic'
        WHEN hcm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM 
    HighCastMovies hcm
LEFT JOIN 
    Directors dc ON hcm.title = (SELECT title FROM aka_title WHERE id = dc.movie_id)
ORDER BY 
    hcm.production_year DESC, hcm.title;
