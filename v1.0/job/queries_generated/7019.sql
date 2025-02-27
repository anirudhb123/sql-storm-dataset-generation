WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
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
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor,
    mk.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.id = mk.movie_id
WHERE 
    rm.actor_rank <= 5
ORDER BY 
    rm.production_year DESC, rm.title;
