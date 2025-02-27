WITH movie_info_filtered AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
),
actor_info AS (
    SELECT 
        p.name AS actor_name,
        c.movie_id,
        c.nr_order,
        r.role
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        r.role LIKE '%Lead%'
)
SELECT 
    mv.movie_id,
    mv.title,
    mv.production_year,
    mv.keywords,
    GROUP_CONCAT(DISTINCT a.actor_name ORDER BY a.nr_order) AS lead_actors
FROM 
    movie_info_filtered mv
LEFT JOIN 
    actor_info a ON mv.movie_id = a.movie_id
GROUP BY 
    mv.movie_id, mv.title, mv.production_year, mv.keywords
ORDER BY 
    mv.production_year DESC, mv.title ASC;

This SQL query performs a series of operations to benchmark string processing across the given schema. It retrieves information for movies produced from the year 2000 onwards, along with their associated keywords and lead actors, organizing them in a structured format. The use of Common Table Expressions (CTEs) helps in breaking down the query for better readability and organization.
