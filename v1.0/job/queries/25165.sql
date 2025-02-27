
WITH MovieData AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        aka_name ak ON ak.person_id = (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = t.id LIMIT 1)
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    LEFT JOIN 
        name c ON c.id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyData AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON cn.id = mc.company_id
    JOIN 
        company_type ct ON ct.id = mc.company_type_id
    GROUP BY 
        mc.movie_id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.aka_names,
    md.cast_names,
    md.keywords,
    cd.company_names,
    cd.company_types
FROM 
    MovieData md
LEFT JOIN 
    CompanyData cd ON cd.movie_id = md.movie_id
ORDER BY 
    md.production_year DESC, md.movie_title;
