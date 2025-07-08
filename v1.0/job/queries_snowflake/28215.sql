WITH popular_titles AS (
    SELECT 
        at.title,
        COUNT(ci.person_id) AS total_cast
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.title
    HAVING 
        COUNT(ci.person_id) > 5
),
cast_roles AS (
    SELECT 
        ak.name AS actor_name,
        rt.role AS role_title,
        at.title AS movie_title,
        at.production_year
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
)
SELECT 
    p.actor_name,
    p.role_title,
    p.movie_title,
    p.production_year,
    pt.total_cast
FROM 
    cast_roles p
JOIN 
    popular_titles pt ON p.movie_title = pt.title
ORDER BY 
    pt.total_cast DESC, 
    p.actor_name;
