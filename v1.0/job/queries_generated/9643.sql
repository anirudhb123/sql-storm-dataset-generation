WITH ranked_titles AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
company_info AS (
    SELECT 
        mc.movie_id, 
        cn.name AS company_name, 
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),
cast_details AS (
    SELECT 
        ci.movie_id, 
        ak.name AS actor_name, 
        rt.role AS role_name
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN role_type rt ON ci.role_id = rt.id
)
SELECT 
    rt.production_year, 
    rt.title, 
    GROUP_CONCAT(DISTINCT cd.actor_name) AS actors, 
    GROUP_CONCAT(DISTINCT ci.company_name) AS companies, 
    GROUP_CONCAT(DISTINCT ci.company_type) AS company_types
FROM ranked_titles rt
LEFT JOIN cast_details cd ON rt.title_id = cd.movie_id
LEFT JOIN company_info ci ON rt.title_id = ci.movie_id
WHERE rt.rank <= 10
GROUP BY rt.production_year, rt.title
ORDER BY rt.production_year DESC, rt.title;
