WITH movie_details AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        ak.name AS nickname,
        k.keyword AS movie_keyword,
        c.kind AS company_type,
        p.info AS person_info
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        person_info p ON a.person_id = p.person_id
    WHERE 
        t.production_year > 2000 
        AND p.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Biography%')
),
ranked_movies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY title) AS rank
    FROM 
        movie_details
)
SELECT 
    production_year,
    COUNT(*) AS number_of_movies,
    STRING_AGG(DISTINCT title, ', ') AS titles,
    STRING_AGG(DISTINCT actor_name || COALESCE(' (' || nickname || ')', ''), ', ') AS actors,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT company_type, ', ') AS companies
FROM 
    ranked_movies
GROUP BY 
    production_year
ORDER BY 
    production_year DESC;
