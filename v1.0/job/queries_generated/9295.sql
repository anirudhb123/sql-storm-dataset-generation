WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_within_year
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        cn.country_code = 'USA' AND
        t.production_year > 2000
    GROUP BY 
        t.id, t.title, t.production_year, a.name
),
TopMovies AS (
    SELECT 
        movie_title, 
        production_year, 
        actor_name
    FROM 
        RankedMovies
    WHERE 
        rank_within_year = 1
)
SELECT 
    DISTINCT tm.movie_title,
    tm.production_year,
    GROUP_CONCAT(tm.actor_name) AS lead_actors
FROM 
    TopMovies tm
JOIN 
    movie_info mi ON tm.movie_title = (SELECT title FROM title WHERE id IN (SELECT movie_id FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'budget')))
GROUP BY 
    tm.movie_title, tm.production_year
ORDER BY 
    tm.production_year DESC;
