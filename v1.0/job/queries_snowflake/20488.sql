
WITH ranked_movies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank,
        COUNT(k.id) OVER (PARTITION BY t.id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
), 
actor_roles AS (
    SELECT 
        c.movie_id,
        c.person_id,
        r.role AS actor_role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
), 
dubious_cast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS num_null_roles
    FROM 
        cast_info c
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        r.role IS NULL
    GROUP BY 
        c.movie_id
    HAVING 
        COUNT(DISTINCT c.person_id) > 1 
)

SELECT 
    m.title_id,
    m.title,
    m.production_year,
    COALESCE(ar.actor_role, 'Unknown') AS actor_role,
    COALESCE(d.num_null_roles, 0) AS dubious_actors,
    CASE 
        WHEN d.num_null_roles IS NOT NULL THEN 'Dubious'
        ELSE 'Clear'
    END AS cast_quality,
    LISTAGG(DISTINCT k.keyword, ', ') AS keywords,
    m.year_rank,
    m.keyword_count
FROM 
    ranked_movies m
LEFT JOIN 
    actor_roles ar ON m.title_id = ar.movie_id AND ar.role_rank <= 3  
LEFT JOIN 
    dubious_cast d ON m.title_id = d.movie_id
LEFT JOIN 
    movie_keyword mk ON m.title_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    m.title_id, m.title, m.production_year, ar.actor_role, d.num_null_roles, m.year_rank, m.keyword_count
ORDER BY 
    m.production_year DESC, m.title;
