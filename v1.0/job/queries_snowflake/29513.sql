
WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        a.name AS actor_name, 
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'documentary'))
    GROUP BY 
        t.title, t.production_year, a.name
),
TopActors AS (
    SELECT 
        actor_name, 
        COUNT(DISTINCT rank) AS years_active
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
    GROUP BY 
        actor_name
)
SELECT 
    ta.actor_name,
    ta.years_active,
    LISTAGG(rm.title || ' (' || rm.production_year || ')', ', ') WITHIN GROUP (ORDER BY rm.production_year DESC) AS movies
FROM 
    TopActors ta
JOIN 
    RankedMovies rm ON ta.actor_name = rm.actor_name
GROUP BY 
    ta.actor_name, ta.years_active
ORDER BY 
    ta.years_active DESC;
