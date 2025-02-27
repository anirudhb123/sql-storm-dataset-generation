WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        a.name AS actor_name,
        ti.title AS movie_title,
        ti.production_year,
        COUNT(*) OVER (PARTITION BY a.id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title ti ON ci.movie_id = ti.movie_id
    WHERE 
        a.name IS NOT NULL
),
TopActors AS (
    SELECT 
        actor_name,
        production_year,
        movie_title,
        movie_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_count DESC) AS actor_rank
    FROM 
        ActorMovies
)
SELECT 
    ta.actor_name,
    ta.movie_title,
    ta.production_year,
    rt.title AS ranked_title,
    rt.year_rank 
FROM 
    TopActors ta
LEFT JOIN 
    RankedTitles rt ON ta.production_year = rt.production_year AND ta.movie_title = rt.title
WHERE 
    ta.actor_rank <= 10 OR rt.year_rank <= 5
ORDER BY 
    ta.production_year DESC,
    ta.movie_count DESC,
    ta.actor_name;
