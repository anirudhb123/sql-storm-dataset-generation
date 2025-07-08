
WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC, m.title ASC) AS year_rank
    FROM title m
),
actor_movies AS (
    SELECT 
        a.person_id,
        m.id AS movie_id,
        r.role AS actor_role,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY m.production_year DESC) AS role_rank
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN title m ON ci.movie_id = m.id
    JOIN role_type r ON ci.role_id = r.id
),
company_movies AS (
    SELECT 
        cm.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies cm
    JOIN company_name c ON cm.company_id = c.id
    JOIN company_type ct ON cm.company_type_id = ct.id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COUNT(DISTINCT am.person_id) AS actor_count,
    LISTAGG(DISTINCT am.actor_role, ', ') WITHIN GROUP (ORDER BY am.actor_role) AS roles,
    LISTAGG(DISTINCT cm.company_name || ' (' || cm.company_type || ')', '; ') WITHIN GROUP (ORDER BY cm.company_name) AS companies
FROM ranked_movies rm
LEFT JOIN actor_movies am ON rm.movie_id = am.movie_id AND am.role_rank <= 2
LEFT JOIN company_movies cm ON rm.movie_id = cm.movie_id
WHERE rm.year_rank <= 5
GROUP BY rm.movie_id, rm.title, rm.production_year
HAVING COUNT(DISTINCT am.person_id) > 1
ORDER BY rm.production_year DESC, actor_count DESC;
