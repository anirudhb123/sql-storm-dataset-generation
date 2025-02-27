WITH MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        r.role AS actor_role,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_order
    FROM title t
    JOIN cast_info ci ON t.id = ci.movie_id
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN role_type r ON ci.role_id = r.id
    WHERE t.production_year >= 2000
),
KeywordDetails AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword m
    JOIN keyword k ON m.keyword_id = k.id
    GROUP BY m.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE ct.kind IS NOT NULL
)
SELECT 
    md.title,
    md.production_year,
    md.actor_name,
    md.actor_role,
    kd.keywords,
    COALESCE(cd.company_name, 'Independent') AS company_name,
    cd.company_type,
    COUNT(md.actor_name) OVER (PARTITION BY md.production_year) AS actor_count_per_year
FROM MovieDetails md
LEFT JOIN KeywordDetails kd ON md.movie_id = kd.movie_id
LEFT JOIN CompanyDetails cd ON md.movie_id = cd.movie_id
WHERE md.actor_order <= 3
ORDER BY md.production_year DESC, md.title;
