WITH ranked_movies AS (
    SELECT 
        at.title AS movie_title,
        a.name AS actor_name,
        COUNT(DISTINCT mc.company_id) AS production_companies,
        ROW_NUMBER() OVER (PARTITION BY at.movie_id ORDER BY at.production_year DESC) AS rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_companies mc ON at.movie_id = mc.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.movie_id, at.title, a.name
),
actor_avg_roles AS (
    SELECT 
        a.name AS actor_name,
        AVG(role_count) AS average_roles
    FROM (
        SELECT 
            a.name AS actor_name,
            COUNT(ci.movie_id) AS role_count
        FROM 
            aka_name a
        JOIN 
            cast_info ci ON a.person_id = ci.person_id
        GROUP BY 
            a.name
    ) AS actor_roles
    GROUP BY 
        a.name
)
SELECT 
    rm.movie_title,
    rm.actor_name,
    rm.production_companies,
    COALESCE(aav.average_roles, 0) AS average_roles_per_actor
FROM 
    ranked_movies rm
LEFT JOIN 
    actor_avg_roles aav ON rm.actor_name = aav.actor_name
WHERE 
    rm.rank = 1
ORDER BY 
    rm.production_companies DESC, rm.movie_title;
