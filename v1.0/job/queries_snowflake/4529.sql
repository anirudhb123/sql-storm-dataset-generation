
WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS title_rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
actor_movies AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        RANK() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_rank
    FROM 
        cast_info c
    INNER JOIN 
        aka_name a ON c.person_id = a.person_id
),
company_info AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rm.title,
    rm.production_year,
    LISTAGG(am.actor_name, ', ') WITHIN GROUP (ORDER BY am.actor_name) AS actors,
    COALESCE(COUNT(DISTINCT ci.company_name), 0) AS company_count,
    SUM(CASE 
        WHEN am.actor_rank = 1 THEN 1 
        ELSE 0 
    END) AS leading_roles
FROM 
    ranked_movies rm
LEFT JOIN 
    actor_movies am ON rm.movie_id = am.movie_id
LEFT JOIN 
    company_info ci ON rm.movie_id = ci.movie_id
WHERE 
    rm.title IS NOT NULL
GROUP BY 
    rm.movie_id, rm.title, rm.production_year
HAVING 
    COUNT(am.actor_name) > 2
ORDER BY 
    rm.production_year DESC, rm.title;
