WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 1990 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),
KeywordStats AS (
    SELECT 
        m.movie_id,
        COUNT(k.id) AS keyword_count,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
FinalBenchmark AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        ks.keyword_count,
        ks.keywords,
        rm.actor_names
    FROM 
        RankedMovies rm
    LEFT JOIN 
        KeywordStats ks ON rm.movie_id = ks.movie_id
)
SELECT 
    *,
    CASE 
        WHEN cast_count < 5 THEN 'Low'
        WHEN cast_count BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'High'
    END AS cast_size_category
FROM 
    FinalBenchmark
ORDER BY 
    production_year DESC, cast_count DESC;
