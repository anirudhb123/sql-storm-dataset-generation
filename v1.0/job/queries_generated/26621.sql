WITH actor_counts AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name AS a
    JOIN 
        cast_info AS ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
),
title_info AS (
    SELECT 
        t.id AS title_id,
        t.title,
        k.keyword AS keyword,
        t.production_year,
        ct.kind AS company_type
    FROM 
        aka_title AS t
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
),
actor_movies AS (
    SELECT 
        a.actor_id,
        ti.title_id,
        ti.title AS movie_title,
        ti.production_year,
        ti.keyword
    FROM 
        actor_counts AS a
    JOIN 
        cast_info AS ci ON a.actor_id = ci.person_id
    JOIN 
        title_info AS ti ON ci.movie_id = ti.title_id
)
SELECT 
    am.actor_id,
    am.movie_title,
    am.production_year,
    STRING_AGG(DISTINCT am.keyword, ', ') AS keywords,
    a.actor_name
FROM 
    actor_movies AS am
JOIN 
    aka_name AS a ON am.actor_id = a.person_id
GROUP BY 
    am.actor_id, am.movie_title, am.production_year, a.actor_name
ORDER BY 
    am.production_year DESC, a.actor_name ASC;
