WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year
),
actor_details AS (
    SELECT 
        p.name AS actor_name,
        r.role AS role_name,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY p.name) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    JOIN 
        aka_title m ON ci.movie_id = m.id
    JOIN 
        role_type r ON ci.role_id = r.id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    ad.actor_name,
    ad.role_name
FROM 
    ranked_movies rm
LEFT JOIN 
    actor_details ad ON rm.production_year = ad.production_year
WHERE 
    rm.rank <= 5 AND 
    (ad.actor_rank IS NULL OR ad.actor_rank <= 3)
ORDER BY 
    rm.production_year DESC, 
    rm.actor_count DESC;
