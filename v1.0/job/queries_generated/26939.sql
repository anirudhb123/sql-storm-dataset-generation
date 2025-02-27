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
        actor_name,
        movie_count
    FROM 
        ActorMovieCounts
    ORDER BY 
        movie_count DESC
    LIMIT 10
),
MoviesWithKeywords AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.title, t.production_year
)
SELECT 
    ta.actor_name,
    mwk.movie_title,
    mwk.production_year,
    mwk.keywords
FROM 
    TopActors ta
JOIN 
    cast_info ci ON ci.person_id = (SELECT ak.id FROM aka_name ak WHERE ak.name = ta.actor_name)
JOIN 
    title t ON t.id = ci.movie_id
JOIN 
    MoviesWithKeywords mwk ON mwk.movie_title = t.title
ORDER BY 
    ta.movie_count DESC, mwk.production_year DESC;
