WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorInfo AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE 0 END) AS average_order
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.id, a.name
),
MovieCast AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COUNT(c.actor_id) AS total_actors
    FROM 
        title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title
)
SELECT 
    rt.title AS title,
    rt.production_year,
    ai.name AS actor_name,
    ai.average_order,
    mc.total_actors,
    COALESCE(NULLIF(mc.total_actors, 0), 'No actors') AS actor_count_display
FROM 
    RankedTitles rt
JOIN 
    ActorInfo ai ON rt.rn = 1 
LEFT JOIN 
    MovieCast mc ON rt.title_id = mc.movie_id
WHERE 
    rt.production_year >= 2000
ORDER BY 
    rt.production_year DESC, rt.title;
