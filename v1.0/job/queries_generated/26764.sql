WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT p.name, ', ') AS actors,
        COUNT(DISTINCT c.id) AS cast_count
    FROM 
        title m
        LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
        LEFT JOIN keyword k ON mk.keyword_id = k.id
        LEFT JOIN cast_info c ON m.id = c.movie_id
        LEFT JOIN aka_name p ON c.person_id = p.person_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
),

CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
        JOIN company_name cn ON mc.company_id = cn.id
        JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.keywords,
    md.actors,
    md.cast_count,
    cd.companies,
    cd.company_types
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyDetails cd ON md.movie_id = cd.movie_id
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC;
