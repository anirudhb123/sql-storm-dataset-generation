WITH RECURSIVE ActorMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movie_titles
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    GROUP BY 
        a.id, a.name
),
TopActors AS (
    SELECT 
        actor_id,
        actor_name,
        movie_count,
        movie_titles,
        RANK() OVER (ORDER BY movie_count DESC) AS actor_rank
    FROM 
        ActorMovies
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title
)
SELECT 
    ta.actor_name,
    ta.movie_count,
    ta.movie_titles,
    mwk.movie_title,
    mwk.keywords
FROM 
    TopActors ta
JOIN 
    cast_info ci ON ta.actor_id = ci.person_id
JOIN 
    MoviesWithKeywords mwk ON ci.movie_id = mwk.movie_id
WHERE 
    ta.actor_rank <= 10
ORDER BY 
    ta.movie_count DESC, mwk.movie_title;