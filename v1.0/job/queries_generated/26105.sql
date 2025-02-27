WITH movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title AS title,
        t.production_year,
        a.name AS actor_name,
        a.surname_pcode,
        k.keyword AS movie_keyword,
        ct.kind AS company_type
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    AND 
        a.name IS NOT NULL
    AND 
        k.keyword IS NOT NULL
),
aggregated_data AS (
    SELECT 
        title_id,
        title,
        production_year,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        COUNT(DISTINCT company_type) AS company_count
    FROM 
        movie_details
    GROUP BY 
        title_id, title, production_year
)
SELECT 
    ad.title_id,
    ad.title,
    ad.production_year,
    ad.actors,
    ad.keywords,
    ad.company_count,
    CASE 
        WHEN ad.company_count > 3 THEN 'High Production'
        WHEN ad.company_count BETWEEN 1 AND 3 THEN 'Moderate Production'
        ELSE 'Low Production'
    END AS production_category
FROM 
    aggregated_data ad
ORDER BY 
    ad.production_year DESC, ad.title;
