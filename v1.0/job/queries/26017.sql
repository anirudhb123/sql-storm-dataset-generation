WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS actor_rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
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
TopActors AS (
    SELECT 
        movie_id,
        STRING_AGG(actor_name, ', ') AS top_actors
    FROM 
        RankedMovies
    WHERE 
        actor_rank <= 3
    GROUP BY 
        movie_id
)
SELECT 
    t.title,
    t.production_year,
    ta.top_actors,
    mk.keywords
FROM 
    aka_title t
LEFT JOIN 
    TopActors ta ON t.id = ta.movie_id
LEFT JOIN 
    MovieKeywords mk ON t.id = mk.movie_id
WHERE 
    t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
ORDER BY 
    t.production_year DESC, 
    t.title;
