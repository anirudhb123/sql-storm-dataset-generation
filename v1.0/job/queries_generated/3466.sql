WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopActors AS (
    SELECT 
        ai.person_id,
        a.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ai.person_id, a.name
    HAVING 
        COUNT(ci.movie_id) > 5
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
    HAVING 
        COUNT(k.id) > 0
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ta.actor_name,
    mwk.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    TopActors ta ON rm.movie_id = (SELECT ci.movie_id FROM cast_info ci WHERE ci.person_id = ta.person_id LIMIT 1)
LEFT JOIN 
    MoviesWithKeywords mwk ON rm.movie_id = mwk.movie_id
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, rm.title ASC;
