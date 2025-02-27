WITH movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT a.name) AS actors
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year, c.name
),
info_details AS (
    SELECT 
        md.title_id,
        md.title,
        md.production_year,
        mi.info AS additional_info
    FROM 
        movie_details md
    LEFT JOIN 
        movie_info mi ON md.title_id = mi.movie_id
)

SELECT 
    id.title_id,
    id.title,
    id.production_year,
    id.additional_info,
    id.keywords,
    id.actors
FROM 
    info_details id
ORDER BY 
    id.production_year DESC,
    id.title ASC;
