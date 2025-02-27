WITH MovieCast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords 
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(CD.company_names, 'Unknown') AS company_names,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        m.production_year,
        COUNT(DISTINCT mc.actor_name) AS actor_count,
        AVG(CASE WHEN mc.role_name = 'Lead' THEN 1 ELSE 0 END) * 100 AS lead_percentage
    FROM 
        aka_title m
    LEFT JOIN 
        (SELECT 
             movie_id, 
             STRING_AGG(DISTINCT cn.name, ', ') AS company_names 
         FROM 
             movie_companies mc
         JOIN 
             company_name cn ON mc.company_id = cn.id 
         GROUP BY 
             mc.movie_id) AS CD ON m.id = CD.movie_id
    LEFT JOIN 
        MovieCast mc ON m.id = mc.movie_id
    LEFT JOIN 
        MovieKeywords mk ON m.id = mk.movie_id
    WHERE 
        m.production_year >= 2000 
    GROUP BY 
        m.id, m.title, CD.company_names, mk.keywords, m.production_year
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.company_names,
    md.keywords,
    md.actor_count,
    md.lead_percentage,
    CASE 
        WHEN md.lead_percentage > 50 THEN 'Majority Leads'
        WHEN md.lead_percentage IS NULL THEN 'No Leads'
        ELSE 'Minority Leads'
    END AS lead_category
FROM 
    MovieDetails md
WHERE 
    md.actor_count > 0
ORDER BY 
    md.production_year DESC, md.actor_count DESC;
