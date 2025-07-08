
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT c.name) AS companies,
        ARRAY_AGG(DISTINCT CONCAT(a.name, ' as ', r.role)) AS cast_members
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
), 
company_count AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT companies) AS company_count
    FROM 
        movie_details
    GROUP BY 
        movie_id
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.keywords,
    md.cast_members,
    cc.company_count
FROM 
    movie_details md
JOIN 
    company_count cc ON md.movie_id = cc.movie_id
ORDER BY 
    md.production_year DESC, 
    cc.company_count DESC, 
    md.movie_title;
