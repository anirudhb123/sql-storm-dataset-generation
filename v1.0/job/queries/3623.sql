
WITH movie_actors AS (
    SELECT 
        c.movie_id, 
        a.name AS actor_name, 
        r.role AS actor_role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
), 
highest_rated_movies AS (
    SELECT 
        m.id AS movie_id, 
        AVG(r.rating::FLOAT) AS avg_rating
    FROM 
        movie_info m
    LEFT JOIN (
        SELECT 
            mi.movie_id, 
            mi.info AS rating
        FROM 
            movie_info mi
        WHERE 
            mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    ) r ON m.id = r.movie_id
    GROUP BY 
        m.id
),
company_movies AS (
    SELECT 
        mc.movie_id, 
        co.name AS company_name, 
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
), 
movie_details AS (
    SELECT 
        t.title, 
        t.production_year, 
        ma.actor_name, 
        ma.actor_role, 
        h.avg_rating, 
        cm.company_name
    FROM 
        title t
    JOIN 
        movie_actors ma ON t.id = ma.movie_id
    JOIN 
        highest_rated_movies h ON t.id = h.movie_id
    LEFT JOIN 
        company_movies cm ON t.id = cm.movie_id
)
SELECT 
    title, 
    production_year, 
    STRING_AGG(DISTINCT CONCAT(actor_name, ' (', actor_role, ')'), ', ') AS actors,
    avg_rating,
    STRING_AGG(DISTINCT company_name, ', ') AS production_companies
FROM 
    movie_details
GROUP BY 
    title, 
    production_year, 
    avg_rating
HAVING 
    avg_rating IS NOT NULL
ORDER BY 
    production_year DESC, 
    avg_rating DESC;
