WITH ActorMovies AS (
    SELECT 
        a.name AS actor_name, 
        t.title AS movie_title, 
        t.production_year, 
        c.nr_order, 
        r.role AS actor_role
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        title t ON c.movie_id = t.id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.name IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        GROUP_CONCAT(k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
ActorMovieDetails AS (
    SELECT 
        am.actor_name,
        am.movie_title,
        am.production_year,
        am.nr_order,
        am.actor_role,
        mk.keywords
    FROM 
        ActorMovies am
    LEFT JOIN 
        MovieKeywords mk ON am.movie_title = mk.movie_title
)
SELECT 
    amd.actor_name,
    AMD.movie_title,
    AMD.production_year,
    AMD.nr_order,
    AMD.actor_role,
    COALESCE(AMD.keywords, 'No keywords') AS keywords
FROM 
    ActorMovieDetails AMD
WHERE 
    AMD.production_year >= 2000
    AND AMD.actor_role LIKE '%Lead%'
ORDER BY 
    AMD.production_year DESC, 
    AMD.actor_name;
