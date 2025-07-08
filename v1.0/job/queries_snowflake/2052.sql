
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
    LISTAGG(a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names
FROM 
    FilteredMovies fm
LEFT JOIN 
    cast_info ci ON fm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON a.person_id = ci.person_id
WHERE 
    fm.cast_count IS NOT NULL AND 
    fm.production_year >= 2000
GROUP BY 
    fm.title, 
    fm.production_year, 
    fm.cast_count
ORDER BY 
    fm.production_year DESC, 
    fm.cast_count DESC;
