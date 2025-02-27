WITH MovieActors AS (
    SELECT 
        a.person_id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        t.title AS movie_title,
        t.production_year,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_position
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
), 
ActorMovies AS (
    SELECT 
        actor_id,
        actor_name,
        COUNT(movie_id) AS total_movies,
        STRING_AGG(movie_title || ' (' || production_year || ')', ', ') AS movie_list
    FROM 
        MovieActors
    GROUP BY 
        actor_id, actor_name
), 
TopActors AS (
    SELECT 
        actor_id,
        actor_name,
        total_movies,
        movie_list,
        RANK() OVER (ORDER BY total_movies DESC) AS ranking
    FROM 
        ActorMovies
),
LastReleasedMovies AS (
    SELECT
        actor_id,
        MAX(production_year) AS last_movie_year
    FROM 
        MovieActors
    GROUP BY 
        actor_id
),
ActorsWithLastMovies AS (
    SELECT 
        a.actor_id,
        a.actor_name,
        a.total_movies,
        a.movie_list,
        lm.last_movie_year
    FROM 
        TopActors a
    LEFT JOIN 
        LastReleasedMovies lm ON a.actor_id = lm.actor_id
    WHERE 
        a.total_movies > 5 
        AND (lm.last_movie_year IS NULL OR lm.last_movie_year > 2000)
),
ActorsWithExtraInfo AS (
    SELECT 
        a.*,
        pi.info AS actor_info
    FROM 
        ActorsWithLastMovies a
    LEFT JOIN 
        person_info pi ON a.actor_id = pi.person_id
    WHERE 
        (pi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography') OR pi.info IS NULL)
)
SELECT 
    a.actor_id,
    a.actor_name,
    a.total_movies,
    a.movie_list,
    a.last_movie_year,
    COALESCE(a.actor_info, 'No additional information available') AS actor_info,
    CASE 
        WHEN a.last_movie_year IS NULL THEN 'No movies released'
        WHEN a.last_movie_year < 2000 THEN 'Active before Y2K'
        ELSE 'Active after Y2K'
    END AS actor_status
FROM 
    ActorsWithExtraInfo a
WHERE 
    a.ranking <= 10
ORDER BY 
    a.total_movies DESC, 
    a.actor_name;
