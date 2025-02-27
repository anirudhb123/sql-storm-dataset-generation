WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title AS title,
        t.production_year,
        k.keyword AS movie_keyword,
        p.name AS person_name,
        r.role AS person_role
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN cast_info c ON t.id = c.movie_id
    JOIN aka_name p ON c.person_id = p.person_id
    JOIN role_type r ON c.role_id = r.id
    WHERE t.production_year >= 2000
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS num_companies
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id, c.name, ct.kind
),
CombinedDetails AS (
    SELECT 
        md.title_id,
        md.title,
        md.production_year,
        md.movie_keyword,
        md.person_name,
        md.person_role,
        cd.company_name,
        cd.company_type,
        cd.num_companies
    FROM MovieDetails md
    LEFT JOIN CompanyDetails cd ON md.title_id = cd.movie_id
)
SELECT 
    title,
    production_year,
    ARRAY_AGG(DISTINCT movie_keyword) AS keywords,
    ARRAY_AGG(DISTINCT person_name || ' (' || person_role || ')') AS cast,
    ARRAY_AGG(DISTINCT company_name || ' (' || company_type || ')') AS companies,
    COUNT(DISTINCT company_name) AS total_companies
FROM CombinedDetails
GROUP BY title_id, title, production_year
ORDER BY production_year DESC, title;
