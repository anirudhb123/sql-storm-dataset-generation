WITH movie_characteristics AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        k.keyword AS movie_keyword,
        r.role AS person_role,
        n.name AS actor_name
    FROM 
        aka_title AS t
    JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    JOIN 
        aka_name AS a ON ci.person_id = a.person_id
    JOIN 
        role_type AS r ON ci.role_id = r.id
    JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    JOIN 
        company_type AS c ON mc.company_type_id = c.id
    JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    JOIN 
        name AS n ON a.person_id = n.imdb_id
    WHERE 
        t.production_year > 2000
        AND k.keyword IS NOT NULL
),
ranked_movies AS (
    SELECT 
        aka_id,
        aka_name,
        movie_title,
        production_year,
        company_type,
        movie_keyword,
        person_role,
        actor_name,
        ROW_NUMBER() OVER (PARTITION BY aka_id ORDER BY production_year DESC) AS rank
    FROM 
        movie_characteristics
)
SELECT 
    aka_id,
    aka_name,
    movie_title,
    production_year,
    company_type,
    movie_keyword,
    person_role,
    actor_name
FROM 
    ranked_movies
WHERE 
    rank = 1
ORDER BY 
    production_year DESC, 
    movie_title;
