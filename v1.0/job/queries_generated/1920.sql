WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) as rank,
        COALESCE(SUM(CASE WHEN c.nr_order IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY a.id), 0) as cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.rank,
        rm.cast_count,
        RANK() OVER (ORDER BY rm.cast_count DESC) as cast_rank
    FROM 
        RankedMovies rm
    WHERE 
        rm.cast_count > 0
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    (SELECT STRING_AGG(name, ', ') 
     FROM aka_name an 
     JOIN cast_info ci ON an.person_id = ci.person_id 
     WHERE ci.movie_id = tm.id) as cast_names
FROM 
    TopMovies tm
WHERE 
    tm.cast_rank <= 10
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
