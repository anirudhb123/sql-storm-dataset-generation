
WITH MovieInfo AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        LISTAGG(DISTINCT c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS companies
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorRoles AS (
    SELECT 
        p.name AS actor_name,
        r.role AS role_name,
        c.movie_id,
        COUNT(CASE WHEN c.nr_order IS NOT NULL THEN 1 END) AS total_appearances
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        p.name, r.role, c.movie_id
),
FinalBenchmark AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        LISTAGG(DISTINCT a.actor_name || ' (' || a.role_name || '): ' || a.total_appearances, '; ') WITHIN GROUP (ORDER BY a.actor_name) AS actor_details
    FROM 
        MovieInfo m
    LEFT JOIN 
        ActorRoles a ON m.movie_id = a.movie_id
    GROUP BY 
        m.movie_id, m.title, m.production_year
)

SELECT 
    fb.movie_id,
    fb.title,
    fb.production_year,
    fb.actor_details,
    CASE 
        WHEN fb.actor_details IS NULL THEN 'No actors listed'
        ELSE 'Actors available'
    END AS actor_status
FROM 
    FinalBenchmark fb
ORDER BY 
    fb.production_year DESC, fb.title;
