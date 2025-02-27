
WITH movie_summary AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies,
        COUNT(DISTINCT ci.person_id) AS cast_count
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
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),

cast_roles AS (
    SELECT 
        ci.movie_id,
        r.role AS cast_role,
        COUNT(DISTINCT ci.person_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, r.role
),

final_benchmark AS (
    SELECT 
        ms.movie_id,
        ms.movie_title,
        ms.production_year,
        ms.keywords,
        ms.companies,
        ms.cast_count,
        cr.cast_role,
        cr.role_count
    FROM 
        movie_summary ms
    LEFT JOIN 
        cast_roles cr ON ms.movie_id = cr.movie_id
)

SELECT 
    movie_id,
    movie_title,
    production_year,
    keywords,
    companies,
    cast_count,
    COALESCE(cast_role, 'No Role') AS cast_role,
    COALESCE(role_count, 0) AS role_count
FROM 
    final_benchmark
ORDER BY 
    production_year DESC, cast_count DESC;
