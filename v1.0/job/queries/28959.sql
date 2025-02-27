WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        c.name AS company_name,
        r.role,
        ak.name AS actor_name
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023 
        AND k.keyword ILIKE '%drama%'
),

info_summary AS (
    SELECT 
        md.movie_id,
        STRING_AGG(md.actor_name, ', ') AS actors,
        STRING_AGG(DISTINCT md.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT md.company_name, ', ') AS production_companies,
        COUNT(DISTINCT md.role) AS unique_roles
    FROM movie_details md
    GROUP BY md.movie_id
)

SELECT 
    t.title,
    t.production_year,
    i.actors,
    i.keywords,
    i.production_companies,
    i.unique_roles
FROM info_summary i
JOIN title t ON i.movie_id = t.id
ORDER BY t.production_year DESC;
