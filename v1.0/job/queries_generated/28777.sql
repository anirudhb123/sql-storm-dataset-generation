WITH movie_details AS (
    SELECT 
        t.id AS movie_id, 
        t.title AS movie_title, 
        t.production_year, 
        GROUP_CONCAT(DISTINCT c.name ORDER BY c.name) AS cast_names, 
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
company_involvement AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS companies,
        GROUP_CONCAT(DISTINCT ct.kind ORDER BY ct.kind) AS company_types
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name cn ON mc.company_id = cn.id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.cast_names,
    md.keywords,
    ci.companies,
    ci.company_types
FROM 
    movie_details md
LEFT JOIN 
    company_involvement ci ON md.movie_id = ci.movie_id
ORDER BY 
    md.production_year DESC, 
    md.movie_title;
