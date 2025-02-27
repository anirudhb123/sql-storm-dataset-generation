WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.role_id) AS roles,
        GROUP_CONCAT(DISTINCT aka.name) AS aliases
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = t.id
    JOIN 
        aka_name aka ON aka.person_id = ci.person_id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    md.movie_title,
    md.production_year,
    cd.company_name,
    cd.company_type,
    md.roles,
    md.aliases
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyDetails cd ON md.movie_id = cd.movie_id
WHERE 
    cd.company_type IS NOT NULL
ORDER BY 
    md.production_year DESC, 
    md.movie_title;
