WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        AVG(CASE WHEN co.company_type_id IS NOT NULL THEN ct.kind END) AS avg_company_type
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        (SELECT DISTINCT movie_id, company_type_id FROM movie_companies) AS co 
        ON t.id = co.movie_id
    WHERE 
        t.production_year BETWEEN 1980 AND 2020
        AND t.title IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
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
    WHERE 
        r.role IS NOT NULL
), 
RatingDetails AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT person_id) AS actor_count,
        COUNT(DISTINCT CASE WHEN r.role ILIKE '%lead%' THEN person_id END) AS lead_actor_count
    FROM 
        ActorRoles r
    GROUP BY 
        movie_id
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keywords,
    COALESCE(rd.actor_count, 0) AS actor_count,
    COALESCE(rd.lead_actor_count, 0) AS lead_actor_count,
    CASE 
        WHEN md.avg_company_type IS NULL THEN 'Undetermined'
        WHEN md.avg_company_type = 'Distributor' THEN 'High Contribution'
        ELSE 'Variable Contribution'
    END AS contribution_category
FROM 
    MovieDetails md
LEFT JOIN 
    RatingDetails rd ON md.movie_id = rd.movie_id
ORDER BY 
    md.production_year DESC, 
    md.title;
