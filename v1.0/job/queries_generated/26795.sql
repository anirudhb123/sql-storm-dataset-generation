WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title m
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
),
KeywordCounts AS (
    SELECT 
        m.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        RankedMovies m ON mk.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        kc.keyword_count
    FROM 
        RankedMovies rm
    JOIN 
        KeywordCounts kc ON rm.movie_id = kc.movie_id
    ORDER BY 
        rm.cast_count DESC, kc.keyword_count DESC
    LIMIT 10
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.keyword_count,
    ARRAY_AGG(DISTINCT ca.name) AS cast_members
FROM 
    TopMovies tm
JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
JOIN 
    aka_name ca ON cc.subject_id = ca.id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.cast_count, tm.keyword_count
ORDER BY 
    tm.production_year DESC;
