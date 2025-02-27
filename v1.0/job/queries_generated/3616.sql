WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        COUNT(DISTINCT kc.keyword) FILTER (WHERE kc.keyword IS NOT NULL) AS keyword_count,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_order
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    GROUP BY 
        m.id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        cp.kind AS company_type,
        COUNT(DISTINCT mc.id) OVER (PARTITION BY mc.movie_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type cp ON mc.company_type_id = cp.id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actors,
    md.keyword_count,
    md.avg_order,
    COALESCE(cd.company_name, 'No Company') AS company_name,
    cd.company_count
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyDetails cd ON md.movie_id = cd.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, 
    md.keyword_count DESC
LIMIT 50;
