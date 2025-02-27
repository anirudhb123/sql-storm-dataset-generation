
WITH RecursiveCast AS (
    SELECT 
        ci.person_id,
        p.name AS person_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
),
TopActors AS (
    SELECT
        person_id,
        person_name,
        COUNT(*) AS movie_count
    FROM
        RecursiveCast
    WHERE
        rn <= 3
    GROUP BY 
        person_id, person_name
    ORDER BY 
        movie_count DESC
    LIMIT 10
)
SELECT 
    a.person_name AS actor_name,
    COUNT(DISTINCT mc.movie_id) AS movies_with_company,
    STRING_AGG(DISTINCT cn.name, ', ') AS companies_worked_with,
    SUM(CASE WHEN t.production_year >= 2000 THEN 1 ELSE 0 END) AS movies_post_2000
FROM 
    TopActors a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
GROUP BY 
    a.person_name
ORDER BY 
    movies_with_company DESC, a.person_name;
