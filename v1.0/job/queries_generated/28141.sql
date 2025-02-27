WITH movie_data AS (
    SELECT 
        t.title,
        t.production_year,
        t.kind_id,
        a.name AS actor_name,
        c.kind AS role_type,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type c ON ci.role_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, a.name, c.kind, t.title, t.production_year, t.kind_id
)

SELECT 
    md.title,
    md.production_year,
    md.actor_name,
    md.role_type,
    md.keywords,
    md.company_count
FROM 
    movie_data md
WHERE 
    md.company_count > 1
ORDER BY 
    md.production_year DESC, 
    md.title;
