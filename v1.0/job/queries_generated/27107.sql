WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT c.role_id) AS cast_roles,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        title t
    JOIN 
        aka_title at ON t.id = at.movie_id
    JOIN 
        cast_info c ON at.movie_id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
company_details AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        GROUP_CONCAT(DISTINCT ct.kind) AS company_types
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
    md.movie_title,
    md.production_year,
    md.aka_names,
    md.cast_roles,
    md.keyword_count,
    cd.company_names,
    cd.company_types
FROM 
    movie_details md
LEFT JOIN 
    company_details cd ON md.movie_title = cd.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, md.movie_title;
