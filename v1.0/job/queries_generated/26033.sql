WITH MovieDetails AS (
    SELECT
        title.title AS movie_title,
        title.production_year,
        aka_title.title AS aka_title,
        ci.person_role_id,
        ci.nr_order,
        p.name AS actor_name,
        rt.role AS actor_role,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
    FROM title
    JOIN aka_title ON title.id = aka_title.movie_id
    JOIN cast_info ci ON title.id = ci.movie_id
    JOIN aka_name p ON ci.person_id = p.person_id
    JOIN role_type rt ON ci.role_id = rt.id
    LEFT JOIN movie_keyword mk ON title.id = mk.movie_id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    GROUP BY title.id, aka_title.id, ci.person_role_id, p.name, rt.role
),
CompanyDetails AS (
    SELECT
        m.title AS movie_title,
        c.name AS company_name,
        ct.kind AS company_type,
        mc.note AS company_note
    FROM movie_companies mc
    JOIN title m ON mc.movie_id = m.id
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),
FullMovieInfo AS (
    SELECT
        md.movie_title,
        md.production_year,
        md.aka_title,
        md.actor_name,
        md.actor_role,
        md.keywords,
        cd.company_name,
        cd.company_type,
        cd.company_note
    FROM MovieDetails md
    LEFT JOIN CompanyDetails cd ON md.movie_title = cd.movie_title
)
SELECT
    movie_title,
    production_year,
    aka_title,
    actor_name,
    actor_role,
    keywords,
    company_name,
    company_type,
    company_note
FROM FullMovieInfo
WHERE 
    production_year >= 2000
    AND (keywords LIKE '%action%' OR keywords LIKE '%comedy%')
ORDER BY production_year DESC, movie_title;
