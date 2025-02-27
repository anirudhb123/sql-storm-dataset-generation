WITH movie_details AS (
    SELECT 
        m.id AS movie_id, 
        m.title,
        m.production_year,
        k.keyword,
        c.kind AS company_type,
        a.name AS actor_name,
        p.gender
    FROM 
        aka_title m
        JOIN movie_keyword mk ON m.id = mk.movie_id
        JOIN keyword k ON mk.keyword_id = k.id
        JOIN movie_companies mc ON m.id = mc.movie_id
        JOIN company_type c ON mc.company_type_id = c.id
        JOIN cast_info ci ON m.id = ci.movie_id
        JOIN aka_name a ON ci.person_id = a.person_id
        JOIN name p ON a.person_id = p.imdb_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
        AND k.keyword ILIKE '%action%'   
),

ranked_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword,
        company_type,
        actor_name,
        gender,
        ROW_NUMBER() OVER (PARTITION BY keyword ORDER BY production_year DESC) AS rank
    FROM 
        movie_details
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.keyword,
    rm.company_type,
    rm.actor_name,
    rm.gender
FROM 
    ranked_movies rm
WHERE 
    rm.rank <= 5  
ORDER BY 
    rm.keyword, 
    rm.production_year DESC;