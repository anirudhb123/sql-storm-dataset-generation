WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS year_rank
    FROM title m
    WHERE m.production_year IS NOT NULL
),
HighestRank AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM RankedMovies
    WHERE year_rank = 1
),
ActorsMovies AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        c.nr_order
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN title t ON c.movie_id = t.id
    WHERE a.name IS NOT NULL
)
SELECT 
    hm.title AS highest_year_movie,
    hm.production_year,
    am.actor_name,
    COUNT(am.movie_title) AS total_appearances,
    STRING_AGG(DISTINCT am.movie_title, ', ') AS movie_list
FROM HighestRank hm
LEFT JOIN ActorsMovies am ON hm.movie_id = am.movie_title
GROUP BY 
    hm.title, 
    hm.production_year, 
    am.actor_name
HAVING 
    COUNT(am.movie_title) > 1
ORDER BY 
    hm.production_year DESC, 
    total_appearances DESC;
