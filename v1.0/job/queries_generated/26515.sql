WITH movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),
actor_roles AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT r.role, ', ') AS roles,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),
detailed_report AS (
    SELECT 
        md.title_id,
        md.title,
        md.production_year,
        md.keywords,
        ar.roles,
        ar.actor_count,
        CASE 
            WHEN ar.actor_count > 10 THEN 'Blockbuster'
            WHEN ar.actor_count BETWEEN 5 AND 10 THEN 'Featured'
            ELSE 'Indie'
        END AS movie_type
    FROM 
        movie_details md
    LEFT JOIN 
        actor_roles ar ON md.title_id = ar.movie_id
)
SELECT 
    title,
    production_year,
    keywords,
    roles,
    actor_count,
    movie_type
FROM 
    detailed_report
ORDER BY 
    production_year DESC, actor_count DESC
LIMIT 100;
