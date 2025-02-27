WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.kind AS company_type,
        a.name AS actor_name,
        COUNT(DISTINCT m.id) AS total_movies
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword, ct.kind, a.name
)
SELECT 
    md.movie_title,
    md.production_year,
    md.movie_keyword,
    md.company_type,
    md.actor_name,
    md.total_movies
FROM 
    movie_details md
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, 
    md.total_movies DESC
LIMIT 100;
