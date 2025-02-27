
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        aka_name ak ON ak.person_id = t.id
    LEFT JOIN 
        cast_info c ON c.movie_id = t.movie_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, '; ') AS company_names,
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
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.aka_names,
    md.cast_count,
    cd.company_names,
    cd.company_types,
    md.keywords
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyDetails cd ON cd.movie_id = md.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, md.movie_title;
