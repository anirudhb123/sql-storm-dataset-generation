
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        title t
    JOIN 
        aka_title at ON t.id = at.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = at.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.title, t.production_year
    ORDER BY 
        cast_count DESC
    LIMIT 10
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, '; ') AS info_details
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.actor_names,
    mk.keywords,
    mi.info_details
FROM 
    RankedMovies rm
LEFT JOIN 
    aka_title at ON rm.title = at.title
LEFT JOIN 
    MovieKeywords mk ON at.movie_id = mk.movie_id
LEFT JOIN 
    MovieInfo mi ON at.movie_id = mi.movie_id
ORDER BY 
    rm.cast_count DESC;
