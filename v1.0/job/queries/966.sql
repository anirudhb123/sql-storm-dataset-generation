
WITH RankedTitles AS (
    SELECT 
        a.id AS title_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    WHERE 
        a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
MoviesWithCast AS (
    SELECT 
        cc.movie_id,
        COUNT(DISTINCT ca.person_id) AS cast_count
    FROM 
        cast_info ca
    JOIN 
        complete_cast cc ON ca.movie_id = cc.movie_id
    GROUP BY 
        cc.movie_id
),
TopMovies AS (
    SELECT 
        rt.title,
        rt.production_year,
        mc.cast_count
    FROM 
        RankedTitles rt
    LEFT JOIN 
        MoviesWithCast mc ON rt.title_id = mc.movie_id
    WHERE 
        rt.year_rank <= 10
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(tm.cast_count, 0) AS cast_count,
    CASE 
        WHEN tm.cast_count IS NULL THEN 'No Cast Information'
        WHEN tm.cast_count > 5 THEN 'Popular Cast'
        ELSE 'Limited Cast'
    END AS cast_info
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, cast_count DESC;
