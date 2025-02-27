WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        rt.role AS main_role,
        COUNT(ci.person_id) AS cast_count
    FROM 
        title m
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year, rt.role
    HAVING 
        COUNT(ci.person_id) > 5
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
company_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.main_role,
    rm.cast_count,
    ks.keywords,
    ci.company_names,
    ci.company_types
FROM 
    ranked_movies rm
LEFT JOIN 
    keyword_summary ks ON rm.movie_id = ks.movie_id
LEFT JOIN 
    company_info ci ON rm.movie_id = ci.movie_id
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
