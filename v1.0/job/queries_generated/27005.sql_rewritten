WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        m.id, m.title, m.production_year
    HAVING 
        COUNT(DISTINCT c.person_id) > 5  
),

KeywordMovies AS (
    SELECT 
        km.movie_id,
        k.keyword,
        COUNT(k.id) AS keyword_count
    FROM 
        movie_keyword km
    JOIN 
        keyword k ON km.keyword_id = k.id
    GROUP BY 
        km.movie_id, k.keyword
),

MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.actors,
        COALESCE(SUM(km.keyword_count), 0) AS total_keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        KeywordMovies km ON rm.movie_id = km.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.cast_count, rm.actors
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.actors,
    md.total_keywords
FROM 
    MovieDetails md
ORDER BY 
    md.total_keywords DESC, 
    md.cast_count DESC
LIMIT 10;