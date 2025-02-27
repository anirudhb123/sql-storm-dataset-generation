WITH RecursiveMovieCTE AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
), 
ActorMovies AS (
    SELECT 
        a.name AS actor_name, 
        COUNT(DISTINCT c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT m.title, ', ') AS movies
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title m ON c.movie_id = m.id
    GROUP BY 
        a.id
), 
MoviesWithRank AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        ARRAY_AGG(a.actor_name) AS actors
    FROM 
        RecursiveMovieCTE r
    LEFT JOIN 
        cast_info c ON r.movie_id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        r.movie_id, r.title, r.production_year
)

SELECT 
    m.title AS movie_title,
    m.production_year,
    COALESCE(a.movie_count, 0) AS number_of_actors,
    m.actors,
    CASE 
        WHEN m.production_year < 2000 THEN 'Classic'
        WHEN m.production_year >= 2000 AND m.production_year <= 2015 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = m.movie_id) AS number_of_production_companies
FROM 
    MoviesWithRank m
LEFT JOIN 
    ActorMovies a ON m.title = a.movies
WHERE 
    m.movie_id IN (SELECT DISTINCT movie_id FROM movie_keyword WHERE keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%drama%'))
ORDER BY 
    m.production_year DESC, 
    m.title
LIMIT 50 OFFSET 0;
