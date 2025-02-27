WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastCounts AS (
    SELECT 
        c.movie_id, 
        COUNT(c.id) AS cast_count 
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        cc.cast_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastCounts cc ON rm.movie_id = cc.movie_id
    WHERE 
        rm.rank <= 5
)
SELECT 
    fm.title, 
    fm.production_year, 
    COALESCE(fm.cast_count, 0) AS cast_count,
    (SELECT STRING_AGG(a.name, ', ') 
     FROM aka_name a 
     JOIN cast_info ci ON a.person_id = ci.person_id 
     WHERE ci.movie_id = fm.movie_id) AS cast_names
FROM 
    FilteredMovies fm
WHERE 
    fm.cast_count IS NOT NULL AND 
    fm.production_year >= 2000
ORDER BY 
    fm.production_year DESC, 
    fm.cast_count DESC;
