
WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        ct.kind AS company_type,
        k.keyword AS movie_keyword,
        (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = t.id) AS cast_count
    FROM
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year > 2000
    ORDER BY 
        t.production_year DESC
),
summary AS (
    SELECT 
        movie_title,
        production_year,
        actor_name,
        COUNT(DISTINCT company_type) AS unique_company_count,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
    FROM 
        movie_details
    GROUP BY 
        movie_title, production_year, actor_name
)
SELECT 
    movie_title, 
    production_year, 
    actor_name, 
    unique_company_count, 
    keywords
FROM 
    summary
WHERE 
    unique_company_count > 2
ORDER BY 
    production_year DESC, 
    actor_name;
