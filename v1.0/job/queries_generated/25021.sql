WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS alternate_names,
        COUNT(DISTINCT CASE WHEN c.role_id IS NOT NULL THEN c.person_id END) AS cast_count,
        COUNT(DISTINCT kw.keyword) AS keyword_count
    FROM 
        aka_title ak
    JOIN 
        title m ON ak.movie_id = m.id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        movie_keyword mw ON m.id = mw.movie_id
    LEFT JOIN 
        keyword kw ON mw.keyword_id = kw.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cc.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cc ON mc.company_id = cc.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.alternate_names,
    md.cast_count,
    md.keyword_count,
    GROUP_CONCAT(DISTINCT cd.company_name || ' (' || cd.company_type || ')') AS companies_involved
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyDetails cd ON md.movie_id = cd.movie_id
GROUP BY 
    md.movie_id, md.title, md.production_year, md.alternate_names, md.cast_count, md.keyword_count
ORDER BY 
    md.production_year DESC, md.title;
