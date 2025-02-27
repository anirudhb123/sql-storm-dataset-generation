WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names
    FROM 
        aka_title ak
    JOIN 
        title t ON ak.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        ROW_NUMBER() OVER (ORDER BY rm.cast_count DESC) AS rank
    FROM 
        RankedMovies rm
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.cast_count,
    string_agg(DISTINCT ak.name, ', ') AS all_aka_names,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    COALESCE(MAX(m.note), 'No notes available') AS movie_note
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = tm.movie_id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
LEFT JOIN 
    movie_info m ON m.movie_id = tm.movie_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.cast_count
ORDER BY 
    tm.cast_count DESC 
LIMIT 10;
