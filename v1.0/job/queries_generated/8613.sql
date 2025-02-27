WITH MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        c.kind AS cast_type,
        GROUP_CONCAT(k.keyword) AS keywords
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    JOIN 
        comp_cast_type c ON c.id = ci.person_role_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        t.id, t.title, t.production_year, a.name, c.kind
),
CompanyDetails AS (
    SELECT 
        m.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        GROUP_CONCAT(DISTINCT ct.kind) AS company_types
    FROM 
        movie_companies m
    JOIN 
        company_name cn ON cn.id = m.company_id
    JOIN 
        company_type ct ON ct.id = m.company_type_id
    GROUP BY 
        m.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.actor_name,
    md.cast_type,
    md.keywords,
    cd.companies,
    cd.company_types
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyDetails cd ON cd.movie_id = md.id
WHERE 
    md.production_year BETWEEN 2000 AND 2023
ORDER BY 
    md.production_year DESC, md.title;
