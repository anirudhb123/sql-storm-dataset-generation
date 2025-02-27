WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name SEPARATOR ', ') AS aka_names,
        GROUP_CONCAT(DISTINCT c.role_id ORDER BY c.nr_order SEPARATOR ', ') AS actors_roles,
        GROUP_CONCAT(DISTINCT kw.keyword ORDER BY kw.keyword SEPARATOR ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        aka_name ak ON ak.person_id IN (
            SELECT person_id FROM cast_info c WHERE c.movie_id = t.id
        )
    LEFT JOIN 
        cast_info c ON c.movie_id = t.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword kw ON kw.id = mk.keyword_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name SEPARATOR ', ') AS company_names,
        GROUP_CONCAT(DISTINCT ct.kind ORDER BY ct.kind SEPARATOR ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.aka_names,
    md.actors_roles,
    ci.company_names,
    ci.company_types,
    COUNT(DISTINCT ci.company_names) AS num_companies
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyInfo ci ON ci.movie_id = md.movie_id
GROUP BY 
    md.movie_id, md.title, md.production_year, md.aka_names, md.actors_roles, ci.company_names, ci.company_types
ORDER BY 
    md.production_year DESC, md.title;
