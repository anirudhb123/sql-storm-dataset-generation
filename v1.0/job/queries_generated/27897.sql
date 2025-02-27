WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        GROUP_CONCAT(DISTINCT c.name ORDER BY c.name SEPARATOR ', ') AS cast_members,
        GROUP_CONCAT(DISTINCT kw.keyword ORDER BY kw.keyword SEPARATOR ', ') AS keywords
    FROM 
        title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = m.id
    LEFT JOIN 
        aka_name c ON c.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        m.production_year >= 2000 
    GROUP BY 
        m.id, m.title, m.production_year
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT co.name ORDER BY co.name SEPARATOR ', ') AS companies,
        GROUP_CONCAT(DISTINCT ct.kind ORDER BY ct.kind SEPARATOR ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_members,
    md.keywords,
    ci.companies,
    ci.company_types
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyInfo ci ON md.movie_id = ci.movie_id
WHERE 
    md.cast_members IS NOT NULL
ORDER BY 
    md.production_year DESC, md.title;
