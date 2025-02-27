WITH movie_data AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        r.role AS person_role,
        a.name AS actor_name,
        k.keyword AS movie_keyword
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year >= 2000
        AND t.kind_id IN (1, 2)
),
company_summary AS (
    SELECT 
        company_name,
        COUNT(DISTINCT movie_id) AS movie_count,
        ARRAY_AGG(DISTINCT title ORDER BY title) AS titles
    FROM 
        movie_data
    GROUP BY 
        company_name
),
actor_summary AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_id) AS movie_count,
        ARRAY_AGG(DISTINCT title ORDER BY title) AS titles
    FROM 
        movie_data
    GROUP BY 
        actor_name
)
SELECT 
    cs.company_name,
    cs.movie_count AS company_movie_count,
    asu.actor_name,
    asu.movie_count AS actor_movie_count,
    cs.titles AS company_titles,
    asu.titles AS actor_titles
FROM 
    company_summary cs
JOIN 
    actor_summary asu ON cs.movie_count > 5 AND asu.movie_count > 5
ORDER BY 
    cs.movie_count DESC, asu.movie_count DESC;
