WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY ci.nr_order) AS role_rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
),
MoviesWithKeywords AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        RankedMovies rm
    JOIN 
        movie_keyword mk ON rm.title_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        rm.title_id, rm.title, rm.production_year
),
ActorsByMovie AS (
    SELECT 
        rm.title_id,
        STRING_AGG(DISTINCT rm.actor_name, ', ') AS actor_names
    FROM 
        RankedMovies rm
    GROUP BY 
        rm.title_id
)

SELECT 
    m.title_id,
    m.title,
    m.production_year,
    a.actor_names,
    m.keywords
FROM 
    MoviesWithKeywords m
JOIN 
    ActorsByMovie a ON m.title_id = a.title_id
ORDER BY 
    m.production_year DESC, 
    m.title;
