WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),
KeywordMovies AS (
    SELECT 
        mw.movie_id,
        STRING_AGG(kw.keyword, ', ') AS keywords
    FROM 
        movie_keyword mw
    JOIN 
        keyword kw ON mw.keyword_id = kw.id
    GROUP BY 
        mw.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.actor_names,
    km.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    KeywordMovies km ON rm.movie_id = km.movie_id
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
