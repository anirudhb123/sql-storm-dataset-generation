WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names
    FROM 
        title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN aka_title ak ON t.id = ak.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),

PersonCastDetails AS (
    SELECT 
        ci.movie_id,
        p.name AS actor_name,
        rt.role AS actor_role,
        COUNT(*) AS total_roles
    FROM 
        cast_info ci
    JOIN aka_name p ON ci.person_id = p.person_id
    JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, p.name, rt.role
)

SELECT 
    md.title_id,
    md.movie_title,
    md.production_year,
    md.movie_keyword,
    md.companies,
    md.aka_names,
    pc.actor_name,
    pc.actor_role,
    pc.total_roles
FROM 
    MovieDetails md
LEFT JOIN PersonCastDetails pc ON md.title_id = pc.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, 
    md.movie_title ASC;

This query benchmarks string processing by analyzing movie titles, their respective companies, alternative names, and casting details. We utilize Common Table Expressions (CTEs) to first aggregate movie details, including keywords and company names, and then to summarize cast information with respect to roles. The final selection filters only movies produced in the year 2000 or later and orders the results by production year and title, showcasing the ability to handle string processing effectively within a complex SQL structure.
