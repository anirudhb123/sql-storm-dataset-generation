WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.kind AS company_type,
        a.name AS actor_name,
        p.gender AS actor_gender
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        name p ON a.id = p.id
)

SELECT 
    md.movie_title,
    md.production_year,
    ARRAY_AGG(DISTINCT md.movie_keyword) AS keywords,
    COUNT(DISTINCT md.actor_name) AS num_actors,
    ARRAY_AGG(DISTINCT md.actor_name) AS actor_names,
    md.company_type
FROM 
    movie_details md
WHERE 
    md.production_year >= 2000
    AND md.actor_gender = 'M'
GROUP BY 
    md.movie_title, md.production_year, md.company_type
ORDER BY 
    md.production_year DESC, num_actors DESC
LIMIT 10;
