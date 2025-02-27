WITH RankedMovies AS (
    SELECT 
        a.id AS actor_id, 
        a.name AS actor_name, 
        t.title AS movie_title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        string_agg(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
ExtensiveMovieInfo AS (
    SELECT 
        m.id AS movie_id, 
        COALESCE(mi.info, 'N/A') AS movie_info, 
        COALESCE(mc.name, 'Independent') AS company_name
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
)
SELECT 
    rm.actor_name, 
    rm.movie_title, 
    rm.production_year, 
    mk.keywords, 
    emi.movie_info, 
    emi.company_name
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_title = mk.movie_id
LEFT JOIN 
    ExtensiveMovieInfo emi ON rm.movie_title = emi.movie_id
WHERE 
    rm.rank = 1 
    AND (rm.production_year >= 2000 OR rm.production_year IS NULL) 
ORDER BY 
    rm.actor_name, 
    rm.production_year DESC;
