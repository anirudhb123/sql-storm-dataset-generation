WITH MovieCast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        t.title AS movie_title,
        t.production_year
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON c.role_id = r.id
    JOIN title t ON c.movie_id = t.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        GROUP_CONCAT(mk.keyword_id) AS keywords
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS company_names,
        GROUP_CONCAT(DISTINCT ct.kind ORDER BY ct.kind) AS company_types
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
)
SELECT 
    mc.movie_id,
    mc.actor_name,
    mc.role_name,
    mc.movie_title,
    mc.production_year,
    mk.keywords,
    cd.company_names,
    cd.company_types
FROM MovieCast mc
JOIN MovieKeywords mk ON mc.movie_id = mk.movie_id
JOIN CompanyDetails cd ON mc.movie_id = cd.movie_id
WHERE mc.production_year >= 2000
ORDER BY mc.production_year DESC, mc.movie_title;
