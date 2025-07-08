WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT c.name) AS companies,
        ARRAY_AGG(DISTINCT a.name) AS actors
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
role_summary AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(ci.id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
inner_query AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keywords,
        md.companies,
        md.actors,
        rs.role,
        rs.role_count
    FROM 
        movie_details md
    LEFT JOIN 
        role_summary rs ON md.movie_id = rs.movie_id
)
SELECT 
    iq.title,
    iq.production_year,
    array_to_string(iq.keywords, ', ') AS keywords,
    array_to_string(iq.companies, ', ') AS companies,
    array_to_string(iq.actors, ', ') AS actors,
    iq.role,
    iq.role_count
FROM 
    inner_query iq
ORDER BY 
    iq.production_year DESC, 
    iq.role_count DESC;