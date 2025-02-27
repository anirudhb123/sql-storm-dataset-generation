WITH movie_years AS (
    SELECT 
        t.production_year, 
        COUNT(DISTINCT c.person_id) AS total_actors,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.production_year
),
actor_details AS (
    SELECT 
        ak.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY ak.name) AS actor_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
)
SELECT 
    my.production_year,
    my.total_actors,
    my.total_companies,
    COALESCE(ad.actor_name, 'Unknown Actor') AS actor_name,
    ad.movie_title,
    ad.actor_rank
FROM 
    movie_years my
LEFT JOIN 
    actor_details ad ON my.production_year = ad.production_year
WHERE
    my.total_actors > 10
ORDER BY 
    my.production_year DESC, ad.actor_rank ASC
LIMIT 100;
