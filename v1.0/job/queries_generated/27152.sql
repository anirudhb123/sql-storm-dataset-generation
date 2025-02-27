WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name) AS aliases,
        k.keyword AS main_keyword,
        comp.name AS company_name
    FROM 
        aka_title ak
    JOIN 
        title t ON ak.movie_id = t.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name comp ON mc.company_id = comp.id
    GROUP BY 
        t.id, t.title, t.production_year, k.id, comp.name
)

SELECT 
    md.movie_title,
    md.production_year,
    md.aliases,
    md.main_keyword,
    COUNT(DISTINCT c.person_id) AS cast_count
FROM 
    movie_details md
JOIN 
    complete_cast cc ON md.movie_id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.id
WHERE 
    md.production_year BETWEEN 1990 AND 2023
GROUP BY 
    md.movie_title, md.production_year, md.aliases, md.main_keyword
ORDER BY 
    md.production_year DESC, cast_count DESC;
