WITH movie_data AS (
    SELECT 
        a.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.name) AS cast_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT co.name) AS companies
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name co ON mc.company_id = co.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        a.id, t.id, t.title, t.production_year
),
person_stats AS (
    SELECT 
        ai.person_id, 
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        ARRAY_AGG(DISTINCT ai.name) AS aliases
    FROM 
        cast_info ci
    JOIN 
        aka_name ai ON ci.person_id = ai.person_id
    GROUP BY 
        ai.person_id
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.cast_names,
    md.keywords,
    md.companies,
    ps.movie_count,
    ps.aliases
FROM 
    movie_data md
LEFT JOIN 
    person_stats ps ON md.movie_id = ps.person_id
ORDER BY 
    md.production_year DESC, 
    md.movie_title;
