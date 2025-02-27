WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_role_counts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        COUNT(DISTINCT ci.role_id) AS role_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
company_movie_info AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rm.title, 
    rm.production_year, 
    COALESCE(ac.actor_count, 0) AS total_actors,
    COALESCE(ac.role_count, 0) AS total_roles,
    STRING_AGG(DISTINCT cm.company_name, ', ') AS production_companies
FROM 
    ranked_movies rm
LEFT JOIN 
    actor_role_counts ac ON rm.movie_id = ac.movie_id
LEFT JOIN 
    company_movie_info cm ON rm.movie_id = cm.movie_id
WHERE 
    rm.title_rank <= 5 -- Top 5 titles per year
GROUP BY 
    rm.movie_id, ac.actor_count, ac.role_count
ORDER BY 
    rm.production_year DESC, 
    rm.title;
