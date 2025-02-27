WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.role_id) AS role_ids,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.id
),
actor_details AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        a.gender,
        GROUP_CONCAT(DISTINCT ci.role_id) AS roles,
        COUNT(DISTINCT m.movie_id) AS movies_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        complete_cast cc ON ci.movie_id = cc.movie_id
    JOIN 
        movie_details m ON cc.movie_id = m.movie_id
    GROUP BY 
        a.id
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    ad.actor_id,
    ad.actor_name,
    ad.gender,
    ad.roles,
    ad.movies_count
FROM 
    movie_details md
JOIN 
    actor_details ad ON md.cast_count = ad.movies_count
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, 
    ad.actor_name ASC;
