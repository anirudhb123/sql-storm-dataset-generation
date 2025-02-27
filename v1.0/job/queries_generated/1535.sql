WITH ranked_movies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rn
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
top_companies AS (
    SELECT 
        c.name AS company_name,
        COUNT(mc.movie_id) AS movie_count
    FROM 
        company_name c
    JOIN 
        movie_companies mc ON c.id = mc.company_id
    GROUP BY 
        c.id, c.name
    HAVING 
        COUNT(mc.movie_id) > 5
),
movies_with_roles AS (
    SELECT 
        mt.title,
        ar.name AS actor_name,
        mt.production_year,
        ci.nr_order,
        RANK() OVER (PARTITION BY mt.id ORDER BY ci.nr_order) AS role_rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ar ON ci.person_id = ar.person_id
)
SELECT 
    r.title,
    r.production_year,
    r.company_count,
    tc.company_name,
    COUNT(mwr.actor_name) AS actor_count,
    AVG(mwr.role_rank) AS average_role_rank
FROM 
    ranked_movies r
LEFT JOIN 
    top_companies tc ON r.company_count > 2
LEFT JOIN 
    movies_with_roles mwr ON r.title = mwr.title AND r.production_year = mwr.production_year
WHERE 
    r.rn <= 10
GROUP BY 
    r.title, r.production_year, r.company_count, tc.company_name
ORDER BY 
    r.production_year DESC, r.company_count DESC;
