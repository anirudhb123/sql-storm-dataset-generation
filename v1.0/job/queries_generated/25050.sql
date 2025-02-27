WITH ActorMovieCount AS (
    SELECT 
        a.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.name
),
TopActors AS (
    SELECT 
        actor_name
    FROM 
        ActorMovieCount
    WHERE 
        movie_count > 10
),
MoviesWithKeywords AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    ta.actor_name,
    mwk.movie_title,
    mwk.production_year,
    STRING_AGG(mwk.keyword, ', ') AS keywords
FROM 
    TopActors ta
JOIN 
    cast_info ci ON ta.actor_name = (SELECT a.name FROM aka_name a WHERE a.person_id = ci.person_id LIMIT 1)
JOIN 
    MoviesWithKeywords mwk ON ci.movie_id = (SELECT title.id FROM title WHERE title.title = mwk.movie_title LIMIT 1)
GROUP BY 
    ta.actor_name, mwk.movie_title, mwk.production_year
ORDER BY 
    ta.actor_name, mwk.production_year DESC;
