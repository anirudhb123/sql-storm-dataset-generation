WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
movie_cast AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        a.name AS actor_name,
        c.note AS role_note
    FROM 
        aka_title m
    INNER JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
company_info AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rt.title,
    rt.production_year,
    mc.actor_name,
    mc.role_note,
    ci.company_name,
    ci.company_type,
    COUNT(DISTINCT mc.actor_name) OVER (PARTITION BY rt.title_id) AS actor_count,
    CASE 
        WHEN ci.company_type IS NULL THEN 'Unknown'
        ELSE ci.company_type
    END AS resolved_company_type
FROM 
    ranked_titles rt
LEFT JOIN 
    movie_cast mc ON rt.title_id = mc.movie_id
LEFT JOIN 
    company_info ci ON mc.movie_id = ci.movie_id
WHERE 
    rt.rank <= 3
AND 
    (mc.role_note IS NOT NULL OR ci.company_name IS NOT NULL)
ORDER BY 
    rt.production_year ASC, rt.title ASC;
