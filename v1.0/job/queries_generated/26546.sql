WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ca ON t.id = ca.movie_id
    JOIN 
        aka_name a ON ca.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
company_info AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keyword,
    md.cast_count,
    md.actor_names,
    COALESCE(ci.company_name, 'N/A') AS company_name,
    COALESCE(ci.company_type, 'N/A') AS company_type,
    ci.company_count
FROM 
    movie_details md
LEFT JOIN 
    company_info ci ON md.movie_id = ci.movie_id
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC, 
    md.title;
