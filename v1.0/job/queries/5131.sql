WITH movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        a.id AS actor_id,
        c.role_id,
        k.keyword,
        com.name AS company_name,
        cp.kind AS company_type
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name com ON mc.company_id = com.id
    JOIN 
        company_type cp ON mc.company_type_id = cp.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year > 2000
),
aggregate_actor_data AS (
    SELECT 
        actor_name,
        COUNT(title_id) AS movie_count,
        STRING_AGG(DISTINCT keyword, ', ') AS keywords
    FROM 
        movie_details
    GROUP BY 
        actor_name
)
SELECT 
    actor_name,
    movie_count,
    keywords
FROM 
    aggregate_actor_data
ORDER BY 
    movie_count DESC
LIMIT 10;
