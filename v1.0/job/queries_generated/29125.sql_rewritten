WITH ActorMovieCount AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.id, a.name
),
PopularMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(*) AS actor_count
    FROM 
        movie_info mi
    JOIN 
        complete_cast cc ON mi.movie_id = cc.movie_id
    JOIN 
        aka_title m ON cc.movie_id = m.id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'tagline') 
    GROUP BY 
        m.id, m.title, m.production_year
    HAVING 
        COUNT(*) > 5
),
ActorPopularMovies AS (
    SELECT 
        am.actor_id,
        am.actor_name,
        pm.movie_title,
        pm.production_year
    FROM 
        ActorMovieCount am
    JOIN 
        cast_info c ON am.actor_id = c.person_id
    JOIN 
        PopularMovies pm ON c.movie_id = pm.movie_id
)
SELECT 
    apm.actor_name,
    COUNT(DISTINCT apm.movie_title) AS number_of_popular_movies,
    STRING_AGG(DISTINCT apm.movie_title, ', ') AS popular_movie_titles
FROM 
    ActorPopularMovies apm
GROUP BY 
    apm.actor_name
ORDER BY 
    number_of_popular_movies DESC
LIMIT 10;