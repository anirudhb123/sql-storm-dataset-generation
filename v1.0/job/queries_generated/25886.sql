WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        string_agg(DISTINCT ak.name, ', ') AS aka_names,
        string_agg(DISTINCT c.name, ', ') AS cast_names,
        COUNT(DISTINCT kw.keyword) AS keyword_count
    FROM
        aka_title ak
    JOIN 
        title m ON ak.movie_id = m.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        string_agg(DISTINCT cn.name, ', ') AS company_names,
        string_agg(DISTINCT ct.kind, ', ') AS company_kinds
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
    md.cast_names,
    md.keyword_count,
    COALESCE(cd.company_names, 'No Companies') AS associated_companies,
    COALESCE(cd.company_kinds, 'N/A') AS company_types
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyDetails cd ON md.movie_id = cd.movie_id
ORDER BY 
    md.production_year DESC, 
    md.keyword_count DESC;
