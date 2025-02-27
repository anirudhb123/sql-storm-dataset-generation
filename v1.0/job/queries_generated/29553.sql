WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS starring_names
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
    ORDER BY 
        cast_count DESC
    LIMIT 10
),
MoviesWithGenres AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        kg.kind AS genre
    FROM 
        RankedMovies rm
    JOIN 
        kind_type kg ON rm.kind_id = kg.id
)
SELECT 
    mw.movie_id,
    mw.title,
    mw.production_year,
    mw.cast_count,
    mw.genre,
    COUNT(DISTINCT m.keyword) AS keyword_count
FROM 
    MoviesWithGenres mw
JOIN 
    movie_keyword mk ON mw.movie_id = mk.movie_id
JOIN 
    keyword m ON mk.keyword_id = m.id
GROUP BY 
    mw.movie_id, mw.title, mw.production_year, mw.cast_count, mw.genre
ORDER BY 
    keyword_count DESC, mw.cast_count DESC;
