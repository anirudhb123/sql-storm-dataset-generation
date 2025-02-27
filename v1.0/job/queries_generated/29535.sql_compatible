
WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword AS movie_keyword,
        STRING_AGG(DISTINCT c.role_id::TEXT, ',') AS role_ids,
        STRING_AGG(DISTINCT a.name, ',') AS actor_names
    FROM title m
    JOIN movie_keyword mk ON m.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN complete_cast cc ON m.id = cc.movie_id
    JOIN cast_info c ON cc.subject_id = c.person_id
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE m.production_year > 2000
    GROUP BY m.id, m.title, m.production_year, k.keyword
),
company_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ',') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ',') AS company_types
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.movie_keyword,
    md.actor_names,
    ci.company_names,
    ci.company_types
FROM movie_details md
LEFT JOIN company_info ci ON md.movie_id = ci.movie_id
ORDER BY md.production_year DESC, md.title;
