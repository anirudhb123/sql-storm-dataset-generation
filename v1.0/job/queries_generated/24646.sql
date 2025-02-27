WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY mt.production_year) AS total_titles
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),

SignificantActors AS (
    SELECT 
        ai.person_id, 
        an.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT at.title, ', ') AS movies 
    FROM 
        aka_name an
    JOIN 
        cast_info ci ON an.person_id = ci.person_id
    JOIN 
        RankedMovies at ON ci.movie_id = at.movie_id
    WHERE 
        ci.nr_order < 10 
    GROUP BY 
        an.person_id, an.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),

FullMovieDetails AS (
    SELECT 
        mt.title,
        mt.production_year,
        COALESCE(ac.name, 'Unknown') AS actor_name,
        COUNT(DISTINCT cmt.movie_id) AS co_actor_count
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info cmt ON mt.id = cmt.movie_id
    LEFT JOIN 
        aka_name ac ON cmt.person_id = ac.person_id
    LEFT JOIN 
        SignificantActors sa ON sa.person_id = cmt.person_id
    WHERE 
        mt.production_year > 2000
    GROUP BY 
        mt.title, mt.production_year, ac.name
)

SELECT 
    movie.title,
    movie.production_year,
    COUNT(DISTINCT actor.name) AS total_actors,
    SUM(CASE WHEN actor.name IS NOT NULL THEN 1 ELSE 0 END) AS known_actors,
    STRING_AGG(DISTINCT actor.name, ', ') AS actor_list,
    RANK() OVER (ORDER BY movie.production_year DESC, total_actors DESC) AS movie_rank
FROM 
    FullMovieDetails movie
LEFT JOIN 
    SignificantActors actor ON movie.actor_name = actor.name
WHERE 
    movie.production_year IS NOT NULL
    AND (movie.production_year BETWEEN 2010 AND 2020 OR movie.production_year IS NULL)
GROUP BY 
    movie.title, movie.production_year
HAVING 
    COUNT(DISTINCT actor.name) > 2
ORDER BY 
    movie.production_year DESC, total_actors DESC;

