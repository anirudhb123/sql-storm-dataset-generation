WITH movie_cast AS (
    SELECT 
        t.title AS movie_title,
        a.name AS actor_name,
        rc.role AS role_name,
        t.production_year
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rc ON ci.role_id = rc.id
    WHERE 
        t.production_year >= 2000 -- filtering for movies from 2000 onwards
),

keyword_count AS (
    SELECT 
        m.movie_id,
        COUNT(mk.keyword_id) AS keyword_total
    FROM 
        movie_keyword mk
    JOIN 
        movie_info mi ON mk.movie_id = mi.movie_id
    GROUP BY 
        m.movie_id
),

company_info AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name SEPARATOR ', ') AS companies,
        GROUP_CONCAT(DISTINCT ct.kind ORDER BY ct.kind SEPARATOR ', ') AS company_types
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
    mc.movie_title,
    mc.actor_name,
    mc.role_name,
    mc.production_year,
    kc.keyword_total,
    ci.companies,
    ci.company_types
FROM 
    movie_cast mc
LEFT JOIN 
    keyword_count kc ON mc.movie_id = kc.movie_id
LEFT JOIN 
    company_info ci ON mc.movie_id = ci.movie_id
ORDER BY 
    mc.production_year DESC,
    mc.movie_title;
