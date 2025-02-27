
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
KeywordMovies AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(keyword.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword ON mk.keyword_id = keyword.id
    GROUP BY 
        mk.movie_id
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(m.info, '; ') AS info_details
    FROM 
        movie_info m
    GROUP BY 
        m.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.actor_names,
    km.keywords,
    mi.info_details
FROM 
    RankedMovies rm
LEFT JOIN 
    KeywordMovies km ON rm.movie_id = km.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC
LIMIT 50;
