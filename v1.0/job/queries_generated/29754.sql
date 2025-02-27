WITH movie_details AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        STRING_AGG(DISTINCT c.name, ', ') AS cast, 
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
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
)
SELECT 
    md.movie_id, 
    md.title, 
    md.production_year, 
    md.cast, 
    md.keywords, 
    cd.companies, 
    cd.company_types
FROM 
    movie_details md
LEFT JOIN 
    company_details cd ON md.movie_id = cd.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, 
    md.title;
