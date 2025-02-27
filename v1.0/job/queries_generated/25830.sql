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
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS actor_role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS role_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
FilteredMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT ar.actor_name) AS actor_count,
        STRING_AGG(DISTINCT ar.actor_name ORDER BY ar.role_rank) AS actor_list
    FROM 
        title m
    JOIN 
        ActorRoles ar ON m.id = ar.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
)
SELECT 
    ft.movie_id,
    ft.title,
    ft.production_year,
    ft.actor_count,
    ft.actor_list,
    rt.title_rank
FROM 
    FilteredMovies ft
JOIN 
    RankedTitles rt ON ft.production_year = rt.production_year AND ft.title = rt.title
WHERE 
    ft.actor_count > 5
ORDER BY 
    ft.production_year DESC, ft.actor_count DESC;
