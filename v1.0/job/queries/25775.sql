WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        m.id, m.title, m.production_year
),
KeywordStats AS (
    SELECT 
        m.movie_id,
        k.keyword,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        RankedMovies m ON mk.movie_id = m.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id, k.keyword
),
AvgKeywordsPerMovie AS (
    SELECT 
        movie_id,
        AVG(keyword_count) AS avg_keyword_count
    FROM 
        KeywordStats
    GROUP BY 
        movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.cast_names,
    ak.avg_keyword_count
FROM 
    RankedMovies rm
LEFT JOIN 
    AvgKeywordsPerMovie ak ON rm.movie_id = ak.movie_id
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
