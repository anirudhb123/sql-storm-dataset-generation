WITH movie_details AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.name) AS companies,
        GROUP_CONCAT(DISTINCT a.name) AS actors
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    LEFT JOIN aka_name a ON ci.person_id = a.person_id
    WHERE t.production_year BETWEEN 2000 AND 2020
    GROUP BY t.id, t.title, t.production_year
),
actor_info AS (
    SELECT 
        a.id AS actor_id, 
        a.name, 
        p.info AS actor_info
    FROM aka_name a
    LEFT JOIN person_info p ON a.person_id = p.person_id
    WHERE p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
),
company_info AS (
    SELECT 
        c.id AS company_id, 
        c.name, 
        ct.kind AS company_type
    FROM company_name c
    JOIN movie_companies mc ON c.id = mc.company_id
    JOIN company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    md.movie_id, 
    md.title, 
    md.production_year, 
    md.keywords, 
    md.companies, 
    md.actors,
    ai.actor_info,
    ci.company_type
FROM movie_details md
LEFT JOIN actor_info ai ON md.actors LIKE '%' || ai.name || '%'
LEFT JOIN company_info ci ON md.companies LIKE '%' || ci.name || '%'
ORDER BY md.production_year DESC, md.title;
