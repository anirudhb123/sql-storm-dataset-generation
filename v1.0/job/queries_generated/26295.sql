WITH movie_characteristics AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        r.role AS character_role,
        p.name AS actor_name
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year >= 2000
        AND k.keyword IS NOT NULL
),
aggregated_data AS (
    SELECT 
        movie_title,
        COUNT(DISTINCT actor_name) AS actor_count,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        MAX(production_year) AS latest_production_year,
        STRING_AGG(DISTINCT company_name, ', ') AS production_companies
    FROM 
        movie_characteristics
    GROUP BY 
        movie_title
)
SELECT 
    movie_title,
    actor_count,
    keywords,
    latest_production_year,
    production_companies
FROM 
    aggregated_data
WHERE 
    actor_count > 5
ORDER BY 
    latest_production_year DESC, actor_count DESC;
