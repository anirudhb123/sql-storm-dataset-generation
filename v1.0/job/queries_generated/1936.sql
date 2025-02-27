WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_roles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles,
        COUNT(ci.person_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, a.name
),
movie_statistics AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END), 0) AS info_count,
        COALESCE(AVG(mi.info_length), 0) AS avg_info_length
    FROM 
        ranked_movies m
    LEFT JOIN (
        SELECT 
            movie_id, 
            info_type_id,
            LENGTH(info) AS info_length
        FROM 
            movie_info
    ) mi ON m.movie_id = mi.movie_id
    GROUP BY 
        m.movie_id, m.title, m.production_year
)

SELECT 
    ms.movie_id,
    ms.title,
    ms.production_year,
    ar.actor_name,
    ar.roles,
    ar.role_count,
    ms.info_count,
    ms.avg_info_length
FROM 
    movie_statistics ms
LEFT JOIN 
    actor_roles ar ON ms.movie_id = ar.movie_id
WHERE 
    ms.production_year > 1990 
    AND ms.title IS NOT NULL
ORDER BY 
    ms.production_year DESC, 
    ar.role_count DESC NULLS LAST
LIMIT 50;
