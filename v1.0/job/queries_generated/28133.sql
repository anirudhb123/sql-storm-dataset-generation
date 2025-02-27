WITH movie_data AS (
    SELECT 
        m.id AS movie_id, 
        m.title AS movie_title, 
        m.production_year,
        GROUP_CONCAT(CASE WHEN c.nr_order IS NOT NULL THEN CONCAT(a.name, ' as ', r.role) END ORDER BY c.nr_order) AS full_cast,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
),
company_data AS (
    SELECT 
        mc.movie_id, 
        GROUP_CONCAT(cn.name) AS companies,
        GROUP_CONCAT(ct.kind) AS company_types
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
        md.movie_title,
        md.production_year,
        md.full_cast,
        md.keywords,
        co.companies,
        co.company_types
    FROM 
        movie_data md
    LEFT JOIN 
        company_data co ON md.movie_id = co.movie_id
)
SELECT 
    fb.movie_id,
    fb.movie_title,
    fb.production_year,
    fb.full_cast,
    fb.keywords,
    fb.companies,
    fb.company_types
FROM 
    final_benchmark fb
ORDER BY 
    fb.production_year DESC, 
    fb.movie_title ASC
LIMIT 100;

