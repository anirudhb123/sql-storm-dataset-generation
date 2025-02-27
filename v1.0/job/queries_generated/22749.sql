WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
cast_summary AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        SUM(CASE WHEN r.role LIKE '%lead%' THEN 1 ELSE 0 END) AS lead_roles_count,
        STRING_AGG(DISTINCT n.name, ', ' ORDER BY n.name) AS lead_actors
    FROM
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        aka_name n ON c.person_id = n.person_id
    GROUP BY 
        c.movie_id
),
keyword_summary AS (
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
movie_company_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
final_summary AS (
    SELECT 
        rt.title,
        rt.production_year,
        cs.total_cast,
        cs.lead_roles_count,
        cs.lead_actors,
        ks.keywords,
        mci.company_names
    FROM 
        ranked_titles rt
    LEFT JOIN 
        cast_summary cs ON rt.title_id = cs.movie_id
    LEFT JOIN 
        keyword_summary ks ON rt.title_id = ks.movie_id
    LEFT JOIN 
        movie_company_info mci ON rt.title_id = mci.movie_id
    WHERE 
        rt.rn = 1
        AND (cs.total_cast IS NOT NULL OR ks.keywords IS NOT NULL)
)
SELECT 
    title,
    production_year,
    COALESCE(total_cast, 0) AS total_cast,
    COALESCE(lead_roles_count, 0) AS lead_roles_count,
    COALESCE(lead_actors, 'No Leads') AS lead_actors,
    COALESCE(keywords, 'No Keywords') AS keywords,
    COALESCE(company_names, 'No Companies') AS company_names
FROM 
    final_summary
ORDER BY 
    production_year DESC, title ASC;
