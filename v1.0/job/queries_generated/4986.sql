WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title, 
        a.production_year, 
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title ASC) AS rank,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY a.id) AS cast_count
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        a.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
        AND a.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        rm.movie_title, 
        rm.production_year, 
        rm.rank, 
        rm.cast_count 
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
TopMovies AS (
    SELECT 
        fm.movie_title, 
        fm.production_year, 
        fm.cast_count,
        COALESCE(mk.keyword_count, 0) AS keyword_count
    FROM 
        FilteredMovies fm
    LEFT JOIN (
        SELECT 
            movie_id, COUNT(keyword_id) AS keyword_count 
        FROM 
            movie_keyword 
        GROUP BY 
            movie_id
    ) mk ON fm.movie_id = mk.movie_id
)
SELECT 
    tm.movie_title, 
    tm.production_year, 
    tm.cast_count,
    CASE 
        WHEN tm.cast_count > 10 THEN 'Large Cast' 
        WHEN tm.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast' 
        ELSE 'Small Cast' 
    END AS cast_size_category,
    STRING_AGG(DISTINCT c.name, ', ') AS unique_actors
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    aka_name c ON cc.person_id = c.person_id
GROUP BY 
    tm.movie_title, tm.production_year, tm.cast_count
ORDER BY 
    tm.production_year DESC, tm.movie_title;
