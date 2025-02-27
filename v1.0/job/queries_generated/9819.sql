WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t 
    WHERE 
        t.production_year IS NOT NULL
),
actor_titles AS (
    SELECT 
        ca.movie_id,
        ak.name AS actor_name,
        rt.title AS title,
        rt.production_year
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        ranked_titles rt ON ci.movie_id = rt.title_id
),
company_info AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    at.actor_name,
    at.title,
    at.production_year,
    ci.company_name,
    ci.company_type
FROM 
    actor_titles at
LEFT JOIN 
    company_info ci ON at.movie_id = ci.movie_id
WHERE 
    at.title_rank <= 5
ORDER BY 
    at.production_year DESC, at.actor_name ASC;
