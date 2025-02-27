
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
company_details AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
complete_details AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_count,
        md.actors,
        cd.companies,
        md.keywords
    FROM 
        movie_details md
    LEFT JOIN 
        company_details cd ON md.movie_id = cd.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    cast_count,
    actors,
    companies,
    keywords
FROM 
    complete_details
WHERE 
    production_year BETWEEN 2000 AND 2020
ORDER BY 
    production_year DESC, 
    cast_count DESC;
