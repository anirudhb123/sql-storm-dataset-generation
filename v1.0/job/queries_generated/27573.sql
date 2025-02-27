WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        kt.kind as kind,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) as year_rank
    FROM 
        title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    WHERE 
        t.production_year >= 2000
),

TopActors AS (
    SELECT 
        ak.person_id,
        ak.name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    GROUP BY 
        ak.person_id, ak.name
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
),

ActorMovies AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year
    FROM 
        TopActors a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
),

Benchmark AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.kind,
        am.actor_name,
        am.movie_title,
        am.production_year AS actor_movie_year
    FROM 
        RankedTitles rt
    LEFT JOIN 
        ActorMovies am ON rt.title = am.movie_title AND rt.production_year = am.production_year
)

SELECT 
    b.title_id,
    b.title,
    b.production_year,
    b.kind,
    COALESCE(b.actor_name, 'No actors found') AS actor_name,
    COUNT(DISTINCT b.actor_name) OVER (PARTITION BY b.title_id) AS actor_count
FROM 
    Benchmark b
ORDER BY 
    b.production_year DESC,
    b.title ASC;
