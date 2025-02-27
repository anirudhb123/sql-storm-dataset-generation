
WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT ci.note, ', ') AS cast_notes,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        t.id AS movie_id
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year, t.id
),
company_details AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.aka_names,
    md.cast_notes,
    md.keywords,
    cd.company_name,
    cd.company_type
FROM 
    movie_details md
LEFT JOIN 
    company_details cd ON md.movie_id = cd.movie_id
ORDER BY 
    md.production_year DESC, 
    md.movie_title;
