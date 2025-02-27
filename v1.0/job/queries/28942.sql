WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
PopularActors AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        RankedTitles rt ON ci.movie_id = rt.title_id
    GROUP BY 
        ci.person_id
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
ActorNames AS (
    SELECT 
        a.person_id,
        a.name
    FROM 
        aka_name a
    JOIN 
        PopularActors pa ON a.person_id = pa.person_id
)

SELECT 
    rt.production_year,
    rt.title,
    an.name AS actor_name,
    COUNT(DISTINCT ci.movie_id) AS total_movies_by_actor
FROM 
    RankedTitles rt
JOIN 
    cast_info ci ON rt.title_id = ci.movie_id
JOIN 
    ActorNames an ON ci.person_id = an.person_id
WHERE 
    rt.title_rank <= 5
GROUP BY 
    rt.production_year, rt.title, an.name
ORDER BY 
    rt.production_year DESC, total_movies_by_actor DESC, rt.title;
