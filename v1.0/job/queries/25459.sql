
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        p.gender,
        STRING_AGG(k.keyword, ',') AS keywords
    FROM title t
    JOIN movie_info mi ON t.id = mi.movie_id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN cast_info ci ON t.id = ci.movie_id
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN name p ON a.person_id = p.imdb_id
    WHERE mi.info_type_id = (SELECT id FROM info_type WHERE info = 'description')
    GROUP BY t.id, t.title, t.production_year, a.name, p.gender
),
company_details AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(c.name, ',') AS companies,
        STRING_AGG(ct.kind, ',') AS company_types
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),
final_benchmark AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.actor_name,
        md.gender,
        md.keywords,
        COALESCE(cd.companies, 'No Companies') AS companies,
        COALESCE(cd.company_types, 'N/A') AS company_types
    FROM movie_details md
    LEFT JOIN company_details cd ON md.movie_id = cd.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    actor_name,
    gender,
    keywords,
    companies,
    company_types
FROM final_benchmark
ORDER BY production_year DESC, actor_name;
