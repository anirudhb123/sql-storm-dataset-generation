WITH movie_cast AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        a.name AS actor_name,
        r.role AS actor_role,
        c.nr_order AS role_order
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        m.production_year > 2000
),
movie_keywords AS (
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
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
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
    mc.movie_id,
    mc.movie_title,
    mc.production_year,
    mc.actor_name,
    mc.actor_role,
    mc.role_order,
    mk.keywords,
    ci.companies,
    ci.company_types
FROM 
    movie_cast mc
LEFT JOIN 
    movie_keywords mk ON mc.movie_id = mk.movie_id
LEFT JOIN 
    company_info ci ON mc.movie_id = ci.movie_id
ORDER BY 
    mc.production_year DESC, 
    mc.movie_title, 
    mc.role_order;
