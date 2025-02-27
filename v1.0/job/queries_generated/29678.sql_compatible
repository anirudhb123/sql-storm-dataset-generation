
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mi.info_type_id) AS info_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023 
        AND k.keyword IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
), 
averaged_details AS (
    SELECT 
        movie_id,
        title,
        production_year,
        AVG(company_count) AS avg_companies,
        AVG(info_count) AS avg_info
    FROM 
        movie_details
    GROUP BY 
        movie_id, title, production_year
)
SELECT 
    md.title,
    md.production_year,
    md.avg_companies,
    md.avg_info
FROM 
    averaged_details md
ORDER BY 
    md.production_year DESC, md.title;
