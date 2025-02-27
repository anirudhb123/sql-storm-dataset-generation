WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        ct.kind AS company_type,
        ARRAY_AGG(DISTINCT a.name) AS actor_names
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        m.id, m.title, m.production_year, k.keyword, c.name, ct.kind
),
info_summary AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        COUNT(DISTINCT md.movie_keyword) AS keyword_count,
        COUNT(DISTINCT md.actor_names) AS actor_count,
        STRING_AGG(DISTINCT md.company_name || ' (' || md.company_type || ')', '; ') AS companies
    FROM 
        movie_details md
    GROUP BY 
        md.movie_id, md.movie_title, md.production_year
)
SELECT 
    mv.movie_id,
    mv.movie_title,
    mv.production_year,
    mv.keyword_count,
    mv.actor_count,
    mv.companies
FROM 
    info_summary mv
WHERE 
    mv.production_year >= 2000
ORDER BY 
    mv.production_year DESC, mv.movie_title ASC
LIMIT 100;