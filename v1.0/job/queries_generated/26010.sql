WITH 
    movie_details AS (
        SELECT 
            t.id AS movie_id,
            t.title,
            t.production_year,
            GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name SEPARATOR ', ') AS aka_names,
            GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords,
            GROUP_CONCAT(DISTINCT c.name ORDER BY c.name SEPARATOR ', ') AS companies
        FROM 
            aka_title t
        LEFT JOIN 
            movie_keyword mk ON t.id = mk.movie_id
        LEFT JOIN 
            keyword k ON mk.keyword_id = k.id
        LEFT JOIN 
            movie_companies mc ON t.id = mc.movie_id
        LEFT JOIN 
            company_name c ON mc.company_id = c.id
        LEFT JOIN 
            aka_name ak ON t.id = ak.person_id
        GROUP BY 
            t.id
    ),
    
    role_summary AS (
        SELECT 
            ci.movie_id,
            r.role,
            COUNT(*) AS role_count
        FROM 
            cast_info ci
        JOIN 
            role_type r ON ci.role_id = r.id
        GROUP BY 
            ci.movie_id, r.role
    )

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.aka_names,
    md.keywords,
    rs.role,
    rs.role_count
FROM 
    movie_details md
LEFT JOIN 
    role_summary rs ON md.movie_id = rs.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, 
    rs.role_count DESC;
