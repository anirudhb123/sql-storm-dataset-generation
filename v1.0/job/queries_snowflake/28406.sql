
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        ARRAY_AGG(DISTINCT kw.keyword) AS keywords,
        COALESCE(COUNT(DISTINCT ci.person_id), 0) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        aka_name ak ON t.id = ak.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY cast_count DESC) AS rank_by_cast
    FROM 
        RankedMovies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.aka_names,
    tm.keywords,
    tm.cast_count,
    COUNT(DISTINCT ci.person_id) FILTER (WHERE ci.note IS NOT NULL) AS notable_cast_count
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
WHERE 
    tm.rank_by_cast <= 10
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.aka_names, tm.keywords, tm.cast_count
ORDER BY 
    tm.cast_count DESC;
