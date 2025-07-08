WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')
),
MovieDetails AS (
    SELECT 
        t.movie_id,
        t.title,
        m.name AS company_name,
        t.production_year,
        COALESCE(m_comp.note, 'No Info') AS company_note
    FROM 
        RankedMovies t
    LEFT JOIN 
        movie_companies m_comp ON t.movie_id = m_comp.movie_id
    LEFT JOIN 
        company_name m ON m_comp.company_id = m.id
    WHERE 
        m.country_code IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
FilteredMovies AS (
    SELECT 
        md.title,
        md.production_year,
        COUNT(ar.name) AS actor_count,
        SUM(CASE WHEN ar.role LIKE '%lead%' THEN 1 ELSE 0 END) AS lead_roles
    FROM 
        MovieDetails md
    LEFT JOIN 
        ActorRoles ar ON md.movie_id = ar.movie_id
    GROUP BY 
        md.movie_id, md.title, md.production_year
)
SELECT 
    fm.title,
    fm.production_year,
    fm.actor_count,
    fm.lead_roles,
    CASE 
        WHEN fm.actor_count > 0 THEN ROUND(fm.lead_roles * 100.0 / fm.actor_count, 2)
        ELSE NULL 
    END AS lead_role_percentage
FROM 
    FilteredMovies fm
WHERE 
    fm.production_year >= 2000
ORDER BY 
    fm.production_year DESC, lead_role_percentage DESC;
