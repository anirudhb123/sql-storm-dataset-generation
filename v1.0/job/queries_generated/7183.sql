WITH movie_actors AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        t.title,
        t.production_year
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
),
company_movie_info AS (
    SELECT 
        m.movie_id,
        m.id AS movie_company_id,
        c.name AS company_name,
        co.kind AS company_kind
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type co ON m.company_type_id = co.id
),
keyword_info AS (
    SELECT 
        mk.movie_id,
        GROUP_CONCAT(k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
final_report AS (
    SELECT 
        ma.actor_name,
        ma.title,
        ma.production_year,
        ci.company_name,
        ci.company_kind,
        ki.keywords
    FROM 
        movie_actors ma
    LEFT JOIN 
        company_movie_info ci ON ma.movie_id = ci.movie_id
    LEFT JOIN 
        keyword_info ki ON ma.movie_id = ki.movie_id
)
SELECT 
    actor_name,
    title,
    production_year,
    company_name,
    company_kind,
    keywords
FROM 
    final_report
ORDER BY 
    production_year DESC, actor_name;
