
WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
actor_movie AS (
    SELECT 
        c.person_id,
        t.title,
        t.production_year,
        COALESCE(r.role, 'Unknown') AS role_type,
        c.movie_id
    FROM 
        cast_info c
    JOIN title t ON c.movie_id = t.id
    LEFT JOIN role_type r ON c.role_id = r.id
),
company_movies AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
    FROM 
        movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    DISTINCT a.name AS actor_name,
    am.title,
    am.production_year,
    cm.companies,
    (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id = am.movie_id) AS actor_count,
    FIRST_VALUE(am.role_type) OVER (PARTITION BY am.title ORDER BY am.role_type DESC) AS primary_role
FROM 
    actor_movie am
JOIN aka_name a ON am.person_id = a.person_id
JOIN company_movies cm ON am.movie_id = cm.movie_id
JOIN ranked_movies rm ON rm.title = am.title
WHERE 
    rm.year_rank <= 3 
    AND COALESCE(am.role_type, 'N/A') != 'Cameo'
GROUP BY 
    a.name, am.title, am.production_year, cm.companies
ORDER BY 
    am.production_year DESC, 
    a.name;
