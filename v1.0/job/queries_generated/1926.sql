WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
), MovieStats AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.year_rank,
        rm.cast_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.year_rank, rm.cast_count
)
SELECT 
    m.title,
    m.production_year,
    m.cast_count,
    COALESCE(kw.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN m.year_rank = 1 THEN 'Latest Release'
        ELSE 'Earlier Release'
    END AS release_status
FROM 
    MovieStats m
LEFT JOIN 
    (SELECT 
        movie_id, COUNT(*) AS keyword_count 
     FROM 
        movie_keyword 
     GROUP BY 
        movie_id) kw ON m.movie_id = kw.movie_id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC,
    m.cast_count DESC;
