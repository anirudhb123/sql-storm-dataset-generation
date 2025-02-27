
WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY CHAR_LENGTH(t.title) DESC) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorFilmography AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS film_count,
        STRING_AGG(DISTINCT t.title, ', ') AS films
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.name
    HAVING 
        COUNT(DISTINCT c.movie_id) > 10
),
TopActors AS (
    SELECT 
        actor_name,
        film_count,
        films,
        RANK() OVER (ORDER BY film_count DESC) AS rank
    FROM 
        ActorFilmography
)
SELECT 
    t.production_year AS production_year,
    t.title AS movie_title,
    COALESCE(a.actor_name, 'Unknown Actor') AS leading_actor,
    CASE 
        WHEN t.production_year < 2000 THEN 'Classic'
        WHEN t.production_year BETWEEN 2000 AND 2010 THEN 'Modern Classic'
        ELSE 'Recent'
    END AS era,
    t.title_rank
FROM 
    RankedTitles t
LEFT JOIN 
    TopActors a ON a.rank = 1 
WHERE 
    t.production_year >= 1990
ORDER BY 
    t.production_year DESC, 
    CHAR_LENGTH(t.title) DESC;
