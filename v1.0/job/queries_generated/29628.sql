WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.type) AS company_types
    FROM title t
    LEFT JOIN aka_title ak ON ak.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword k ON k.id = mk.keyword_id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_type c ON c.id = mc.company_type_id
    WHERE t.production_year BETWEEN 2000 AND 2023
    GROUP BY t.id
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT r.role ORDER BY r.role) AS roles
    FROM cast_info ci
    LEFT JOIN role_type r ON r.id = ci.person_role_id
    GROUP BY ci.movie_id
)
SELECT 
    md.title_id,
    md.title,
    md.production_year,
    md.kind_id,
    md.aka_names,
    md.keywords,
    cd.total_cast,
    cd.roles,
    COUNT(DISTINCT mc.company_id) AS num_companies
FROM MovieDetails md
LEFT JOIN CastDetails cd ON cd.movie_id = md.title_id
LEFT JOIN movie_companies mc ON mc.movie_id = md.title_id
GROUP BY 
    md.title_id, 
    md.title, 
    md.production_year, 
    md.kind_id, 
    md.aka_names, 
    md.keywords, 
    cd.total_cast, 
    cd.roles
ORDER BY 
    md.production_year DESC, 
    md.title;
