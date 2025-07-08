
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actors,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
), MoviesWithKeywords AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        rm.actors,
        COALESCE(LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword), '') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        rm.movie_id, rm.movie_title, rm.production_year, rm.cast_count, rm.actors
)
SELECT 
    mwk.movie_id,
    mwk.movie_title,
    mwk.production_year,
    mwk.cast_count,
    mwk.actors,
    mwk.keywords
FROM 
    MoviesWithKeywords mwk
WHERE 
    mwk.cast_count > 5
ORDER BY 
    mwk.production_year DESC, mwk.cast_count DESC
LIMIT 10;
