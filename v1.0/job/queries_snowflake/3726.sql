
WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        rm.cast_count,
        RANK() OVER (ORDER BY rm.production_year, rm.cast_count DESC) AS movie_rank
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn <= 5
)
SELECT 
    tm.title, 
    tm.production_year, 
    tm.cast_count,
    COALESCE(mi.info, 'No Additional Info') AS additional_info,
    CASE 
        WHEN tm.cast_count > 10 THEN 'Popular'
        WHEN tm.cast_count BETWEEN 5 AND 10 THEN 'Moderately Popular'
        ELSE 'Less Popular' 
    END AS popularity_category
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info mi ON mi.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1)
LEFT JOIN 
    (SELECT person_id, movie_id FROM cast_info) ci ON ci.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1)
LEFT JOIN 
    person_info pi ON pi.person_id = ci.person_id
WHERE 
    tm.movie_rank <= 10
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
