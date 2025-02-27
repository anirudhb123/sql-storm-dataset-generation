
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        aka_title m
    INNER JOIN 
        cast_info c ON m.id = c.movie_id
    INNER JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),
KeywordStats AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.cast_names,
    ks.keyword_count,
    ks.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    KeywordStats ks ON rm.movie_id = ks.movie_id
ORDER BY 
    rm.production_year DESC,
    rm.cast_count DESC,
    rm.title;
