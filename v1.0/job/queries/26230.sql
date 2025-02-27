WITH movie_titles AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        k.keyword AS movie_keyword,
        ct.kind AS company_type 
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        t.production_year > 2000 
        AND k.keyword IS NOT NULL
),
actor_info AS (
    SELECT 
        a.name AS actor_name, 
        COUNT(ci.movie_id) AS movie_count, 
        SUM(CASE WHEN ci.person_role_id = 1 THEN 1 ELSE 0 END) AS lead_roles 
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.name
)
SELECT 
    mt.title, 
    mt.production_year, 
    mt.movie_keyword, 
    ai.actor_name,
    ai.movie_count,
    ai.lead_roles
FROM 
    movie_titles mt
JOIN 
    complete_cast cc ON mt.movie_id = cc.movie_id
JOIN 
    actor_info ai ON cc.subject_id = (SELECT id FROM aka_name WHERE name = ai.actor_name LIMIT 1)
WHERE 
    mt.production_year > 2010 
ORDER BY 
    mt.production_year DESC, 
    ai.movie_count DESC
LIMIT 100;
