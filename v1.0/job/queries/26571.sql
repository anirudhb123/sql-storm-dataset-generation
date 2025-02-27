
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ',') AS keywords,
        c.kind AS company_type,
        STRING_AGG(DISTINCT a.name, ',') AS actors
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_type c ON mc.company_type_id = c.id
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.person_id
    JOIN aka_name a ON ci.person_id = a.person_id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year, c.kind
),
role_summary AS (
    SELECT 
        t.id AS movie_id,
        r.role AS role_type,
        COUNT(ci.id) AS role_count
    FROM title t
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.person_id
    JOIN role_type r ON ci.role_id = r.id
    GROUP BY t.id, r.role
),
final_summary AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keywords,
        md.company_type,
        md.actors,
        rs.role_type,
        rs.role_count
    FROM movie_details md
    LEFT JOIN role_summary rs ON md.movie_id = rs.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    keywords,
    company_type,
    actors,
    role_type,
    role_count
FROM final_summary
ORDER BY production_year DESC, title;
