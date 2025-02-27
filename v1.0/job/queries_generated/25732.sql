WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.role_id ORDER BY c.nr_order) AS roles,
        GROUP_CONCAT(DISTINCT a.name ORDER BY a.name) AS actors
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.nr_order IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
keyword_summary AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
extended_movie_info AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.roles,
        md.actors,
        ks.keywords
    FROM 
        movie_details md
    LEFT JOIN 
        keyword_summary ks ON md.movie_id = ks.movie_id
)
SELECT 
    emi.movie_title,
    emi.production_year,
    emi.roles,
    emi.actors,
    emi.keywords,
    COUNT(DISTINCT c.id) AS company_count,
    COUNT(DISTINCT i.id) AS info_count
FROM 
    extended_movie_info emi
LEFT JOIN 
    movie_companies mc ON emi.movie_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_info i ON emi.movie_id = i.movie_id
GROUP BY 
    emi.movie_title, emi.production_year, emi.roles, emi.actors, emi.keywords
ORDER BY 
    emi.production_year DESC, emi.movie_title ASC
LIMIT 100;
