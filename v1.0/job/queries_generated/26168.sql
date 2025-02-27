WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT a.name ORDER BY a.name) AS actors,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
company_details AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS companies,
        GROUP_CONCAT(DISTINCT ct.kind ORDER BY ct.kind) AS company_types
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
    md.actors,
    cd.companies,
    cd.company_types,
    md.keywords
FROM 
    movie_details md
LEFT JOIN 
    company_details cd ON md.movie_id = cd.movie_id
ORDER BY 
    md.production_year DESC, md.title;
