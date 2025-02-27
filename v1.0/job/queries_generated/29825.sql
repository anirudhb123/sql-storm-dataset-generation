WITH movie_actors AS (
    SELECT 
        a.name AS actor_name, 
        m.title AS movie_title, 
        m.production_year, 
        c.nr_order AS actor_order,
        (SELECT GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) 
         FROM movie_keyword mk 
         JOIN keyword k ON mk.keyword_id = k.id 
         WHERE mk.movie_id = m.id) AS keywords
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title m ON c.movie_id = m.id
    WHERE 
        a.name IS NOT NULL
),
company_info AS (
    SELECT 
        m.id AS movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        GROUP_CONCAT(DISTINCT ct.kind) AS company_types
    FROM 
        movie_companies m
    JOIN 
        company_name cn ON m.company_id = cn.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    GROUP BY 
        m.id
),
movie_details AS (
    SELECT 
        ma.actor_name, 
        ma.movie_title,
        ma.production_year,
        ma.actor_order,
        ci.company_names,
        ci.company_types,
        ma.keywords
    FROM 
        movie_actors ma
    LEFT JOIN 
        company_info ci ON ma.movie_title = ci.movie_id
)
SELECT 
    actor_name, 
    movie_title, 
    production_year, 
    actor_order, 
    company_names,
    company_types,
    keywords
FROM 
    movie_details
WHERE 
    production_year BETWEEN 2000 AND 2023
ORDER BY 
    production_year DESC, 
    actor_order;
