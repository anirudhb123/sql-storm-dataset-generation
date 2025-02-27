
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT aka.name, ', ') AS alternative_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        aka_name aka ON cc.subject_id = aka.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
company_details AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
final_benchmark AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.alternative_names,
        md.keywords,
        cd.companies,
        cd.company_types
    FROM 
        movie_details md
    LEFT JOIN 
        company_details cd ON md.movie_id = cd.movie_id
)
SELECT 
    movie_id, 
    title, 
    production_year, 
    COALESCE(alternative_names, 'N/A') AS alternative_names, 
    COALESCE(keywords, 'N/A') AS keywords, 
    COALESCE(companies, 'N/A') AS companies, 
    COALESCE(company_types, 'N/A') AS company_types
FROM 
    final_benchmark
ORDER BY 
    production_year DESC, 
    title ASC;
