WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCount AS (
    SELECT 
        c.movie_id,
        COUNT(*) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
FilteredTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        ac.actor_count
    FROM 
        RankedTitles rt
    LEFT JOIN 
        ActorCount ac ON rt.title_id = ac.movie_id
    WHERE 
        ac.actor_count > 5 OR ac.actor_count IS NULL
)
SELECT 
    ft.title,
    ft.production_year,
    COALESCE(ft.actor_count, 0) AS actor_count,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = ft.title_id) AS keyword_count,
    (SELECT STRING_AGG(DISTINCT kw.keyword, ', ') 
     FROM movie_keyword mk 
     JOIN keyword kw ON mk.keyword_id = kw.id 
     WHERE mk.movie_id = ft.title_id) AS keywords
FROM 
    FilteredTitles ft
WHERE 
    ft.production_year BETWEEN 2000 AND 2023
ORDER BY 
    ft.production_year DESC, ft.title;
