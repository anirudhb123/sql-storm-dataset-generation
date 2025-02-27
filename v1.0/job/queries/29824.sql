WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS actor_count,
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
    ORDER BY 
        actor_count DESC
    LIMIT 10
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS movie_details
    FROM 
        RankedMovies m
    JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    GROUP BY 
        m.movie_id
),
KeywordStats AS (
    SELECT 
        m.movie_id,
        COUNT(mk.id) AS keyword_count,
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
    rm.actor_count,
    rm.actor_names,
    mi.movie_details,
    ks.keyword_count,
    ks.keywords
FROM 
    RankedMovies rm
JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
JOIN 
    KeywordStats ks ON rm.movie_id = ks.movie_id
ORDER BY 
    rm.actor_count DESC;
