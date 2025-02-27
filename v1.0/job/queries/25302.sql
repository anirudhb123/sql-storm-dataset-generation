WITH movie_roles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS actor_name,
        c.movie_id,
        a.person_id
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    WHERE 
        a.name IS NOT NULL
),
title_info AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        k.phonetic_code AS keyword_code
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year > 2000
),
actor_movie_details AS (
    SELECT 
        mr.actor_name,
        ti.title,
        ti.production_year,
        COUNT(mr.movie_id) AS role_count,
        STRING_AGG(DISTINCT ti.keyword, ', ') AS keywords
    FROM 
        movie_roles mr
    JOIN 
        title_info ti ON mr.movie_id = ti.title_id
    GROUP BY 
        mr.actor_name, ti.title, ti.production_year
)
SELECT 
    amd.actor_name,
    amd.title,
    amd.production_year,
    amd.role_count,
    amd.keywords
FROM 
    actor_movie_details amd
WHERE 
    amd.role_count > 2
ORDER BY 
    amd.production_year DESC, amd.role_count DESC;
