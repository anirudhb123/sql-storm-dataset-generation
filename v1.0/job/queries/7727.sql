
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(mk.id) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        aka_title at ON t.id = at.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
    ORDER BY 
        keyword_count DESC
    LIMIT 10
),
cast_roles AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(ci.person_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        ci.nr_order < 5
    GROUP BY 
        ci.movie_id, rt.role
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    cr.role,
    cr.role_count,
    cn.name AS company_name,
    cn.country_code
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_roles cr ON rm.movie_id = cr.movie_id
LEFT JOIN 
    movie_companies mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
ORDER BY 
    rm.production_year DESC, rm.keyword_count DESC, cr.role_count DESC;
