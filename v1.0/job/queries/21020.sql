WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id AS actor_id,
        t.title AS movie_title,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL AND c.nr_order IS NOT NULL
), 
MovieData AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id = m.id) AS total_cast,
        COALESCE((SELECT STRING_AGG(DISTINCT k.keyword, ', ') FROM movie_keyword mk JOIN keyword k ON mk.keyword_id = k.id WHERE mk.movie_id = m.id), 'No Keywords') AS keywords
    FROM 
        aka_title m
    WHERE 
        m.production_year > 1990
),
ActorMovieStats AS (
    SELECT 
        a.actor_id,
        COUNT(DISTINCT a.movie_title) AS num_movies,
        MAX(a.movie_title) AS latest_movie,
        MIN(a.movie_title) AS earliest_movie
    FROM 
        ActorHierarchy a
    GROUP BY 
        a.actor_id
)
SELECT 
    md.title AS movie_title,
    md.production_year,
    md.total_cast,
    ams.num_movies,
    ams.latest_movie,
    ams.earliest_movie,
    CASE 
        WHEN md.total_cast IS NULL THEN 'No Cast Info' 
        WHEN ams.num_movies > 5 THEN 'A Busy Actor'
        ELSE 'An Emerging Talent'
    END AS actor_status,
    a.actor_id,
    COALESCE(a.actor_order, 0) AS cast_order
FROM 
    MovieData md
LEFT JOIN 
    ActorMovieStats ams ON md.movie_id = ams.actor_id
LEFT JOIN 
    ActorHierarchy a ON md.title = a.movie_title
ORDER BY 
    md.production_year DESC,
    a.actor_order IS NULL, 
    a.actor_order ASC
LIMIT 100;
