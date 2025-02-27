WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        r.role AS person_role,
        c.person_id,
        a.name AS actor_name,
        c.nr_order
    FROM title t
    JOIN cast_info c ON t.id = c.movie_id
    JOIN role_type r ON c.role_id = r.id
    JOIN aka_name a ON c.person_id = a.person_id
),
KeywordDetails AS (
    SELECT 
        md.movie_title,
        md.production_year,
        k.keyword
    FROM MovieDetails md
    JOIN movie_keyword mk ON mk.movie_id = (
        SELECT id FROM title WHERE title = md.movie_title AND production_year = md.production_year LIMIT 1
    )
    JOIN keyword k ON k.id = mk.keyword_id
),
CompanyDetails AS (
    SELECT 
        md.movie_title,
        md.production_year,
        GROUP_CONCAT(DISTINCT cn.name) AS companies
    FROM MovieDetails md
    JOIN movie_companies mc ON mc.movie_id = (
        SELECT id FROM title WHERE title = md.movie_title AND production_year = md.production_year LIMIT 1
    )
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY md.movie_title, md.production_year
)
SELECT 
    md.movie_title,
    md.production_year,
    GROUP_CONCAT(DISTINCT kd.keyword) AS keywords,
    cd.companies,
    GROUP_CONCAT(DISTINCT CONCAT(a.actor_name, ' as ', md.person_role) ORDER BY md.nr_order) AS cast
FROM MovieDetails md
JOIN KeywordDetails kd ON md.movie_title = kd.movie_title AND md.production_year = kd.production_year
JOIN CompanyDetails cd ON md.movie_title = cd.movie_title AND md.production_year = cd.production_year
GROUP BY md.movie_title, md.production_year, cd.companies
ORDER BY md.production_year DESC, md.movie_title;
