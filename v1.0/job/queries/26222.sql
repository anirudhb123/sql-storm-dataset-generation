
WITH movie_data AS (
    SELECT 
        m.id AS movie_id, 
        m.title AS movie_title, 
        m.production_year AS year, 
        STRING_AGG(a.name, ', ') AS actor_names,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        m.id, m.title, m.production_year
),
company_data AS (
    SELECT 
        mc.movie_id, 
        COUNT(DISTINCT cn.name) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.year,
    md.actor_names,
    COALESCE(cd.company_count, 0) AS company_count,
    COALESCE(cd.companies, 'No Companies') AS companies,
    md.keyword_count
FROM 
    movie_data md
LEFT JOIN 
    company_data cd ON md.movie_id = cd.movie_id
ORDER BY 
    md.year DESC, 
    md.keyword_count DESC;
