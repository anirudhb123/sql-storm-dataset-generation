WITH MovieDetails AS (
    SELECT t.id AS movie_id,
           t.title,
           t.production_year,
           a.name AS primary_actor,
           r.role AS role,
           GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
           COALESCE(COUNT(c.id), 0) AS cast_count
    FROM title t
    LEFT JOIN cast_info c ON t.id = c.movie_id
    LEFT JOIN aka_name a ON c.person_id = a.person_id
    LEFT JOIN role_type r ON c.role_id = r.id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year, a.name, r.role
),
CompanyDetails AS (
    SELECT mc.movie_id,
           ARRAY_AGG(DISTINCT cn.name) AS companies,
           ARRAY_AGG(DISTINCT ct.kind) AS company_types
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
)
SELECT md.movie_id,
       md.title,
       md.production_year,
       md.primary_actor,
       md.role,
       md.keywords,
       cd.companies,
       cd.company_types,
       md.cast_count
FROM MovieDetails md
LEFT JOIN CompanyDetails cd ON md.movie_id = cd.movie_id
ORDER BY md.production_year DESC, md.title;
