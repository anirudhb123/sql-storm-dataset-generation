
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), actor_movies AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        COUNT(*) AS num_roles
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id, ak.name
), company_movies AS (
    SELECT 
        mc.movie_id,
        LISTAGG(cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    rt.title,
    rt.production_year,
    am.actor_name,
    am.num_roles,
    cm.companies
FROM 
    ranked_titles rt
LEFT JOIN 
    actor_movies am ON rt.title_id = am.movie_id
LEFT JOIN 
    company_movies cm ON rt.title_id = cm.movie_id
WHERE 
    rt.rank <= 5
ORDER BY 
    rt.production_year DESC, rt.title;
