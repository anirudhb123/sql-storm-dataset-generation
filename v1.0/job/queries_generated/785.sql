WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(SUM(CASE WHEN cc.person_role_id = 1 THEN 1 ELSE 0 END), 0) AS lead_actor_count,
        COALESCE(SUM(CASE WHEN cc.person_role_id IN (2, 3) THEN 1 ELSE 0 END), 0) AS supporting_actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COALESCE(SUM(cc.nr_order), 0) DESC) AS movie_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info cc ON t.id = cc.movie_id
    GROUP BY 
        t.id
),
filtered_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.lead_actor_count,
        rm.supporting_actor_count
    FROM 
        ranked_movies rm
    WHERE 
        rm.movie_rank <= 10
),
company_movie_info AS (
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
    fm.title,
    fm.production_year,
    fm.lead_actor_count,
    fm.supporting_actor_count,
    STRING_AGG(DISTINCT cmi.company_name || ' (' || cmi.company_type || ')', '; ') AS companies
FROM 
    filtered_movies fm
LEFT JOIN 
    company_movie_info cmi ON fm.movie_id = cmi.movie_id
GROUP BY 
    fm.movie_id, fm.title, fm.production_year, fm.lead_actor_count, fm.supporting_actor_count
ORDER BY 
    fm.production_year DESC, fm.lead_actor_count DESC;
