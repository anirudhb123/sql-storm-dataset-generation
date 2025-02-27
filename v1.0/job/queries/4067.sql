WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year
    FROM 
        RankedMovies rm 
    WHERE 
        rm.rank_year <= 5
),
MovieCast AS (
    SELECT 
        mo.movie_id, 
        COUNT(DISTINCT ca.person_id) AS total_cast 
    FROM 
        TopMovies mo
    JOIN 
        cast_info ca ON mo.movie_id = ca.movie_id
    GROUP BY 
        mo.movie_id
)
SELECT 
    tm.title, 
    tm.production_year, 
    COALESCE(mc.total_cast, 0) AS total_cast, 
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = tm.movie_id AND mi.note IS NOT NULL) AS info_count,
    (SELECT STRING_AGG(kw.keyword, ', ') 
     FROM movie_keyword mk 
     JOIN keyword kw ON mk.keyword_id = kw.id 
     WHERE mk.movie_id = tm.movie_id) AS keywords,
    CASE 
        WHEN mc.total_cast IS NULL THEN 'No Cast Information'
        WHEN mc.total_cast > 10 THEN 'Large Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM 
    TopMovies tm
LEFT JOIN 
    MovieCast mc ON tm.movie_id = mc.movie_id
ORDER BY 
    tm.production_year DESC, 
    total_cast DESC;
