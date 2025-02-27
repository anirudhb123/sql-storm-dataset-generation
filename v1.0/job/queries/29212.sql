WITH MovieRoles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(c.person_id) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.person_role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COALESCE(mr.role, 'No Roles') AS roles_summary
    FROM 
        aka_title m
    LEFT JOIN 
        MovieKeywords mk ON m.id = mk.movie_id
    LEFT JOIN 
        MovieRoles mr ON m.id = mr.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, '; ') AS companies,
        STRING_AGG(DISTINCT ct.kind, '; ') AS company_types
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
    COALESCE(cd.companies, 'No Companies') AS companies,
    COALESCE(cd.company_types, 'No Company Types') AS company_types,
    md.keywords,
    md.roles_summary
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyDetails cd ON md.movie_id = cd.movie_id
ORDER BY 
    md.production_year DESC, md.title ASC;
