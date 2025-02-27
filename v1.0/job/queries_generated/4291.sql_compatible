
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        m.movie_id,
        m.title,
        COALESCE(c.count, 0) AS cast_count,
        COALESCE(k.keywords, '') AS movie_keywords,
        m.production_year
    FROM 
        RankedMovies m
    LEFT JOIN (
        SELECT 
            movie_id,
            COUNT(*) AS count
        FROM 
            cast_info
        GROUP BY 
            movie_id
    ) c ON m.movie_id = c.movie_id
    LEFT JOIN (
        SELECT 
            mk.movie_id,
            STRING_AGG(k.keyword, ', ') AS keywords
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON mk.keyword_id = k.id
        GROUP BY 
            mk.movie_id
    ) k ON m.movie_id = k.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.movie_keywords,
    (SELECT AVG(cast_count) 
     FROM MovieDetails 
     WHERE production_year = md.production_year) AS avg_cast_count,
    (SELECT COUNT(DISTINCT p.id) 
     FROM person_info p 
     JOIN cast_info ci ON ci.person_id = p.person_id 
     WHERE ci.movie_id = md.movie_id) AS unique_actors
FROM 
    MovieDetails md
WHERE 
    md.cast_count > (SELECT AVG(cast_count) 
                     FROM MovieDetails)
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC
LIMIT 100;
