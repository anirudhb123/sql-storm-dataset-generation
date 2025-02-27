WITH movie_actors AS (
    SELECT 
        a.name AS actor_name,
        c.movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    JOIN 
        aka_title t ON t.id = c.movie_id
), 
keyword_count AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS total_keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
),
company_info AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        ct.kind AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON cn.id = mc.company_id
    JOIN 
        company_type ct ON ct.id = mc.company_type_id
    GROUP BY 
        mc.movie_id
)
SELECT 
    ma.actor_name,
    ma.movie_id,
    ma.title,
    ma.production_year,
    kc.total_keywords,
    ci.companies,
    ci.company_types,
    COUNT(ma.actor_name) OVER (PARTITION BY ma.movie_id) AS total_actors
FROM 
    movie_actors ma
LEFT JOIN 
    keyword_count kc ON kc.movie_id = ma.movie_id
LEFT JOIN 
    company_info ci ON ci.movie_id = ma.movie_id
WHERE 
    ma.production_year >= 2000
ORDER BY 
    ma.production_year DESC, 
    ma.movie_id, 
    ma.actor_order;
