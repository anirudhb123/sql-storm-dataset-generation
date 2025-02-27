WITH ActorMovies AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        aka_name AS a
    JOIN 
        cast_info AS ci ON a.person_id = ci.person_id
    JOIN 
        aka_title AS t ON ci.movie_id = t.movie_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
        AND t.production_year IS NOT NULL
),
TopActors AS (
    SELECT 
        actor_name, 
        COUNT(*) AS movie_count
    FROM 
        ActorMovies
    WHERE 
        movie_rank <= 3
    GROUP BY 
        actor_name
    HAVING 
        COUNT(*) > 1
),
MovieKeywords AS (
    SELECT 
        t.title AS movie_title,
        k.keyword AS keyword
    FROM 
        aka_title AS t
    JOIN 
        movie_keyword AS mk ON t.movie_id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
)
SELECT 
    ta.actor_name,
    ta.movie_count,
    STRING_AGG(mk.keyword, ', ') AS keywords
FROM 
    TopActors AS ta
LEFT JOIN 
    ActorMovies AS am ON ta.actor_name = am.actor_name
LEFT JOIN 
    MovieKeywords AS mk ON am.movie_title = mk.movie_title
WHERE 
    ta.movie_count > 2
GROUP BY 
    ta.actor_name, ta.movie_count
ORDER BY 
    ta.movie_count DESC, ta.actor_name ASC
LIMIT 10;
