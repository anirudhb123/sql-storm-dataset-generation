WITH ActorMovieCounts AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name
),
TopActors AS (
    SELECT 
        actor_name
    FROM 
        ActorMovieCounts
    ORDER BY 
        movie_count DESC
    LIMIT 10
),
MoviesWithKeywords AS (
    SELECT 
        m.title AS movie_title,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.title
),
ActorsInTopMovies AS (
    SELECT 
        ta.actor_name,
        mw.movie_title
    FROM 
        TopActors ta
    JOIN 
        cast_info ci ON ta.actor_name = (SELECT ak.name FROM aka_name ak WHERE ak.person_id = ci.person_id)
    JOIN 
        title mw ON ci.movie_id = mw.id
)
SELECT 
    at.actor_name,
    COUNT(DISTINCT mw.movie_title) AS movies_played,
    GROUP_CONCAT(DISTINCT mw.keywords) AS keywords
FROM 
    ActorsInTopMovies at
JOIN 
    MoviesWithKeywords mw ON at.movie_title = mw.movie_title
GROUP BY 
    at.actor_name
ORDER BY 
    movies_played DESC;
