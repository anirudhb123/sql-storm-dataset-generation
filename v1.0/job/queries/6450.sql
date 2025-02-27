WITH RankedTitles AS (
    SELECT 
        t.title, 
        t.production_year, 
        t.kind_id, 
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) as rank
    FROM 
        title t
    WHERE 
        t.production_year >= 2000
),
ActorTitles AS (
    SELECT 
        a.name AS actor_name, 
        at.title AS title, 
        at.production_year
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    WHERE 
        a.name IS NOT NULL
),
FilteredTitles AS (
    SELECT 
        rt.title, 
        rt.production_year, 
        rt.kind_id
    FROM 
        RankedTitles rt
    WHERE 
        rt.rank <= 5
)
SELECT 
    ft.title, 
    ft.production_year, 
    COUNT(at.actor_name) AS actor_count
FROM 
    FilteredTitles ft
LEFT JOIN 
    ActorTitles at ON ft.title = at.title AND ft.production_year = at.production_year
GROUP BY 
    ft.title, ft.production_year
ORDER BY 
    ft.production_year DESC, COUNT(at.actor_name) DESC;
