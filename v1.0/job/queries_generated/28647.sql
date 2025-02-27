WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
), ActorRoles AS (
    SELECT 
        a.name AS actor_name,
        r.role AS role_name,
        c.movie_id,
        SUM(CASE WHEN c.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS total_roles
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        a.name, r.role
)
SELECT 
    rt.title,
    rt.production_year,
    rt.keyword,
    ar.actor_name,
    ar.role_name,
    ar.total_roles
FROM 
    RankedTitles rt
JOIN 
    complete_cast cc ON rt.production_year = cc.movie_id
JOIN 
    ActorRoles ar ON cc.subject_id = ar.movie_id
WHERE 
    rt.year_rank <= 10
ORDER BY 
    rt.production_year, ar.total_roles DESC;

This SQL query benchmarks string processing by extracting data from various related tables and performing complex joins while considering production years, actor roles, and keywords. The use of common table expressions (CTEs) allows for intermediate computations, specifically ranking titles by year and aggregating actor roles. The final results display top titles filtering out only the recent ones while showcasing the most prolific actor roles per movie, fostering richer insights into the relationships within the cinema dataset.
