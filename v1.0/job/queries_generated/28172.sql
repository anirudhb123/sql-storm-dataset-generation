WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        ct.kind AS company_type,
        a.name AS actor_name,
        p.gender AS actor_gender,
        ci.nr_order AS cast_order
    FROM 
        aka_title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        name p ON a.person_id = p.imdb_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
        AND m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    ORDER BY 
        m.production_year DESC,
        ci.nr_order
)

SELECT 
    movie_id,
    movie_title,
    production_year,
    GROUP_CONCAT(actor_name || ' (' || actor_gender || ')', ', ') AS actors,
    GROUP_CONCAT(movie_keyword, ', ') AS keywords,
    company_name,
    company_type
FROM 
    movie_details
GROUP BY 
    movie_id, movie_title, production_year, company_name, company_type
HAVING 
    COUNT(DISTINCT a.person_id) >= 3
ORDER BY 
    production_year DESC;
