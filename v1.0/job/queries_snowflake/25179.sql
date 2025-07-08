WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS keyword,
        ARRAY_AGG(DISTINCT c.name) AS cast_names
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        aka_name c ON cc.subject_id = c.person_id
    GROUP BY 
        m.id, k.keyword, m.title, m.production_year
),

CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
),

CombinedDetails AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.keyword,
        md.cast_names,
        COALESCE(cd.company_name, 'Unknown') AS company_name,
        COALESCE(cd.company_type, 'Unknown') AS company_type,
        COALESCE(cd.total_companies, 0) AS total_companies
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyDetails cd ON md.movie_id = cd.movie_id
)

SELECT 
    movie_id,
    movie_title,
    production_year,
    keyword,
    cast_names,
    company_name,
    company_type,
    total_companies
FROM 
    CombinedDetails
WHERE 
    production_year BETWEEN 2000 AND 2023
ORDER BY 
    production_year DESC, movie_title
LIMIT 100;

