WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        p.name AS person_name,
        r.role,
        COUNT(DISTINCT c.id) AS company_count,
        COUNT(DISTINCT ca.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ca ON cc.subject_id = ca.person_id
    JOIN 
        name p ON ca.person_id = p.id
    JOIN 
        role_type r ON ca.role_id = r.id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword, c.name, p.name, r.role
)
SELECT 
    md.title,
    md.production_year,
    md.movie_keyword,
    md.company_name,
    md.person_name,
    md.role,
    md.company_count,
    md.cast_count
FROM 
    movie_details md
WHERE 
    md.production_year BETWEEN 2000 AND 2020
    AND md.movie_keyword IS NOT NULL
ORDER BY 
    md.production_year DESC, 
    md.title ASC;
