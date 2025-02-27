WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
), 
DirectorMovies AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(cn.name ORDER BY cn.name) AS director_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.imdb_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        ct.kind = 'Director'
    GROUP BY 
        mc.movie_id
), 
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        dm.director_names
    FROM 
        RankedMovies rm
    LEFT JOIN 
        DirectorMovies dm ON rm.movie_id = dm.movie_id
    WHERE 
        rm.rank <= 10
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(tm.director_names, 'Unknown Director') AS directors,
    tm.cast_count,
    CASE 
        WHEN tm.cast_count > 5 THEN 'Ensemble Cast'
        WHEN tm.cast_count IS NULL THEN 'No Cast Info'
        ELSE 'Small Cast'
    END AS cast_size
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
