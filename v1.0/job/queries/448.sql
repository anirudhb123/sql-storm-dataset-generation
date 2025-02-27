
WITH MovieData AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM title t
    LEFT JOIN cast_info c ON t.id = c.movie_id
    LEFT JOIN aka_name a ON c.person_id = a.person_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY t.id, t.title, t.production_year
),
CompanyData AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),
CompleteData AS (
    SELECT 
        md.title_id,
        md.title,
        md.production_year,
        md.actor_count,
        md.actors,
        cd.companies,
        cd.company_types
    FROM MovieData md
    LEFT JOIN CompanyData cd ON md.title_id = cd.movie_id
)
SELECT 
    cd.title_id,
    cd.title,
    cd.production_year,
    COALESCE(cd.actor_count, 0) AS actor_count,
    COALESCE(cd.actors, 'No actors') AS actors,
    COALESCE(cd.companies, 'No companies') AS companies,
    COALESCE(cd.company_types, 'No company types') AS company_types
FROM CompleteData cd
WHERE cd.production_year >= 2000 
AND cd.actor_count > (SELECT AVG(actor_count) FROM MovieData)
ORDER BY cd.production_year DESC, cd.actor_count DESC;
