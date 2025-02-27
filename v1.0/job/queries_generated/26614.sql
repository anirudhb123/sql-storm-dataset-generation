WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        ct.kind AS company_type,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        COALESCE(SUM(mk.movie_id), 0) AS total_keywords,
        COUNT(DISTINCT ca.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id 
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        cast_info ca ON t.movie_id = ca.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ca.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year, c.name, ct.kind
    HAVING 
        COUNT(DISTINCT ca.person_id) >= 5
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.company_name,
    md.company_type,
    md.aka_names,
    md.keywords,
    md.total_keywords,
    md.cast_count
FROM 
    movie_details md
WHERE 
    md.total_keywords > 0
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC
LIMIT 10;
