WITH RankedMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
),
ActorTitles AS (
    SELECT 
        rm.actor_id,
        rm.actor_name,
        COUNT(DISTINCT rm.title_id) AS total_movies,
        MAX(rm.production_year) AS latest_movie_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn <= 10
    GROUP BY 
        rm.actor_id, rm.actor_name
),
TopActors AS (
    SELECT 
        actor_id,
        actor_name,
        total_movies,
        latest_movie_year,
        RANK() OVER (ORDER BY total_movies DESC) AS rank
    FROM 
        ActorTitles
)
SELECT 
    ta.actor_id,
    ta.actor_name,
    COALESCE(ta.total_movies, 0) AS total_movies,
    COALESCE(ta.latest_movie_year, 'N/A') AS latest_movie_year,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
FROM 
    TopActors ta
LEFT JOIN 
    movie_keyword mk ON ta.actor_id = mk.movie_id
WHERE 
    ta.rank <= 10
GROUP BY 
    ta.actor_id, ta.actor_name
ORDER BY 
    total_movies DESC, ta.actor_name;
