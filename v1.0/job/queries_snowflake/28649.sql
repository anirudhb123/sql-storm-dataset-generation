WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS primary_keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
),

TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        primary_keyword
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),

ActorsInTopMovies AS (
    SELECT 
        a.name AS actor_name,
        tm.movie_title,
        tm.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        TopMovies tm ON c.movie_id = tm.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        a.name, tm.movie_title, tm.production_year
)

SELECT 
    a.actor_name,
    SUM(a.actor_count) AS total_appearances
FROM 
    ActorsInTopMovies a
GROUP BY 
    a.actor_name
ORDER BY 
    total_appearances DESC
LIMIT 10;
