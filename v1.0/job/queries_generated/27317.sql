WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aliases,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM
        aka_title ak
    JOIN
        title t ON ak.movie_id = t.id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        t.id
),
cast_details AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        p.name AS actor_name,
        rt.role AS role
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
complete_details AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        cd.actor_name,
        cd.role,
        md.aliases,
        md.keywords
    FROM 
        movie_details md
    JOIN 
        cast_details cd ON md.movie_id = cd.movie_id
)
SELECT 
    cd.movie_id,
    cd.movie_title,
    cd.production_year,
    cd.actor_name,
    cd.role,
    cd.aliases,
    cd.keywords
FROM 
    complete_details cd
WHERE 
    cd.production_year >= 2000
ORDER BY 
    cd.production_year DESC, 
    cd.movie_title ASC
LIMIT 100;
