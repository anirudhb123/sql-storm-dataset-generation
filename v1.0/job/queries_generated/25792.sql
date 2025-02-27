WITH MovieDetails AS (
    SELECT 
        m.title AS movie_title,
        m.production_year,
        k.keyword AS genre,
        GROUP_CONCAT(DISTINCT a.name) AS actors,
        GROUP_CONCAT(DISTINCT cp.name) AS companies,
        GROUP_CONCAT(DISTINCT r.role) AS roles
    FROM 
        aka_title AS m
    JOIN 
        movie_keyword AS mk ON m.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    JOIN 
        cast_info AS ci ON m.id = ci.movie_id
    JOIN 
        aka_name AS a ON ci.person_id = a.person_id
    JOIN 
        movie_companies AS mc ON m.id = mc.movie_id
    JOIN 
        company_name AS cp ON mc.company_id = cp.id
    JOIN 
        role_type AS r ON ci.role_id = r.id
    GROUP BY 
        m.id, m.title, m.production_year
),
Ranking AS (
    SELECT 
        movie_title,
        production_year,
        genre,
        actors,
        companies,
        roles,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY COUNT(DISTINCT actors) DESC) AS actor_rank
    FROM 
        MovieDetails
)
SELECT 
    movie_title,
    production_year,
    genre,
    actors,
    companies,
    roles,
    actor_rank
FROM 
    Ranking
WHERE 
    production_year >= 2000
ORDER BY 
    actor_rank, production_year;
