WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_year
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
), 
DirectorMovies AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS director_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        r.role = 'Director'
    GROUP BY 
        c.movie_id
), 
TopMovies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        dm.director_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        DirectorMovies dm ON rm.title_id = dm.movie_id
    WHERE 
        rm.rank_by_year <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(tm.director_count, 0) AS director_count,
    COUNT(mk.keyword_id) AS keyword_count
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON tm.title_id = mk.movie_id
GROUP BY 
    tm.title_id, tm.title, tm.production_year, tm.director_count
HAVING 
    COUNT(mk.keyword_id) > 2
ORDER BY 
    tm.production_year DESC, keyword_count DESC;
