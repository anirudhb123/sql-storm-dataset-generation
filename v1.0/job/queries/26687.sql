WITH movie_data AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title AS t
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info AS ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
company_data AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies AS mc
    LEFT JOIN 
        company_name AS cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
final_output AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_count,
        md.aka_names,
        md.keywords,
        coalesce(cd.company_names, 'No Companies') AS company_names,
        coalesce(cd.company_types, 'No Company Types') AS company_types
    FROM 
        movie_data AS md
    LEFT JOIN 
        company_data AS cd ON md.movie_id = cd.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    cast_count,
    aka_names,
    keywords,
    company_names,
    company_types
FROM 
    final_output
WHERE 
    production_year BETWEEN 2000 AND 2023
ORDER BY 
    production_year DESC, 
    cast_count DESC;
