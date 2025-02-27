WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS ranking
    FROM 
        aka_title AS m
    WHERE 
        m.production_year IS NOT NULL
),
top_movies AS (
    SELECT 
        DISTINCT r.movie_id,
        r.title,
        r.production_year
    FROM 
        ranked_movies AS r
    WHERE 
        r.ranking <= 5
),
movie_cast AS (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info AS c
    JOIN 
        aka_name AS a ON c.person_id = a.person_id
    JOIN 
        role_type AS r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
company_movie_info AS (
    SELECT 
        mc.movie_id,
        COALESCE(GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name), 'No Company') AS companies
    FROM 
        movie_companies AS mc
    LEFT JOIN 
        company_name AS cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    t.title,
    t.production_year,
    COALESCE(m.actors, 'No Actors') AS actors,
    COALESCE(m.roles, 'No Roles') AS roles,
    c.companies
FROM 
    top_movies AS t
LEFT JOIN 
    movie_cast AS m ON t.movie_id = m.movie_id
LEFT JOIN 
    company_movie_info AS c ON t.movie_id = c.movie_id
WHERE 
    t.production_year = 2021
    OR (t.production_year IS NULL AND c.companies LIKE '%Warner Bros%')
ORDER BY 
    t.title;
