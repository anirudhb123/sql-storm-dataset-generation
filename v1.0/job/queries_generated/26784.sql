WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT a.name) AS actors,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.name) AS companies
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        t.id
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.actors,
    md.keywords,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count,
    COUNT(DISTINCT mc.company_id) AS company_count
FROM 
    movie_details md
JOIN 
    movie_info mi ON md.movie_id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    it.info ILIKE '%drama%'
GROUP BY 
    md.movie_id, md.movie_title, md.production_year, md.actors, md.keywords
ORDER BY 
    md.production_year DESC, md.movie_title;

