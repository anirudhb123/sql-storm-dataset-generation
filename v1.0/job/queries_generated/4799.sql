WITH MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        ka.name AS actor_name,
        COUNT(ml.linked_movie_id) AS link_count,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY ka.name) AS actor_order
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        aka_name ka ON cc.subject_id = ka.person_id
    LEFT JOIN 
        movie_link ml ON t.id = ml.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year, ka.name
),

CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    md.title,
    md.production_year,
    md.actor_name,
    cs.company_count,
    cs.company_names,
    COALESCE(md.link_count, 0) AS link_count,
    CASE 
        WHEN md.actor_order = 1 THEN 'Lead Actor'
        WHEN md.actor_order <= 3 THEN 'Supporting Actor'
        ELSE 'Minor Role'
    END AS actor_role
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyStats cs ON md.id = cs.movie_id
WHERE 
    (md.actor_name IS NOT NULL AND cs.company_count > 0)
ORDER BY 
    md.production_year DESC, md.title;
