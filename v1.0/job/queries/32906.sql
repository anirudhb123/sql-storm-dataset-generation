
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    UNION ALL
    SELECT 
        m.id,
        m.title,
        m.production_year,
        h.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        MovieHierarchy h ON m.episode_of_id = h.movie_id
),
TopMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COUNT(DISTINCT c.person_id) AS actor_count,
        m.production_year,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
    HAVING 
        COUNT(DISTINCT c.person_id) > 5
),
PopularActors AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ca.movie_id) AS movies_played_in,
        RANK() OVER (ORDER BY COUNT(ca.movie_id) DESC) AS actor_rank
    FROM 
        aka_name ak
    INNER JOIN 
        cast_info ca ON ak.person_id = ca.person_id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.name
    HAVING 
        COUNT(DISTINCT ca.movie_id) > 10
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.actor_count,
    a.actor_name,
    a.movies_played_in
FROM 
    TopMovies m
LEFT JOIN 
    PopularActors a ON a.actor_rank <= 5
WHERE 
    m.rank <= 10
ORDER BY 
    m.actor_count DESC, m.production_year DESC;
