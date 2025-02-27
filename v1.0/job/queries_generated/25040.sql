WITH MovieDetails AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        c.name AS actor_name,
        r.role AS actor_role
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.production_year BETWEEN 2000 AND 2020
),

KeywordFiltered AS (
    SELECT 
        md.movie_id,
        GROUP_CONCAT(k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

CompanyDetails AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(c.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    md.movie_title,
    md.production_year,
    md.actor_name,
    md.actor_role,
    kf.keywords,
    cd.companies
FROM 
    MovieDetails md
LEFT JOIN 
    KeywordFiltered kf ON md.movie_title = kf.movie_id
LEFT JOIN 
    CompanyDetails cd ON md.movie_title = cd.movie_id
ORDER BY 
    md.production_year DESC, md.movie_title;
