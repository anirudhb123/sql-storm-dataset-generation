WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name) AS cast_names,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
company_info AS (
    SELECT 
        m.id AS movie_id,
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
    md.cast_names,
    md.keywords,
    ci.company_name,
    ci.company_type
FROM 
    movie_details md
LEFT JOIN 
    company_info ci ON md.movie_id = ci.movie_id
ORDER BY 
    md.production_year DESC, 
    md.movie_title;
