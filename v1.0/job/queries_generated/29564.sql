WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS total_keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CombinedStats AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        rm.cast_names,
        COALESCE(ks.total_keywords, 0) AS total_keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        KeywordStats ks ON rm.movie_id = ks.movie_id
)
SELECT 
    cs.movie_id,
    cs.title,
    cs.production_year,
    cs.total_cast,
    cs.cast_names,
    cs.total_keywords,
    (cs.total_cast + cs.total_keywords) AS benchmark_score
FROM 
    CombinedStats cs
ORDER BY 
    benchmark_score DESC
LIMIT 10;
