WITH RECURSIVE 
-- CTE to enumerate all cast members for each movie along with their roles and production year
cast_hierarchy AS (
    SELECT 
        c.id AS cast_id,
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
), 
-- CTE to summarize movies and their associated keywords and companies
movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        COALESCE(CSTRING_AGG(DISTINCT COALESCE(cn.name, 'Unknown Company'), ', '), 'No Companies') AS companies
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        t.id, t.title
), 
-- CTE to calculate the average role length and total number of actors in each movie
role_summary AS (
    SELECT 
        movie_id,
        AVG(LENGTH(role_name)) AS avg_role_length,
        COUNT(DISTINCT cast_id) AS total_actors
    FROM 
        cast_hierarchy
    GROUP BY 
        movie_id
)

SELECT 
    md.title,
    md.keyword,
    md.companies,
    COALESCE(rs.avg_role_length, 0) AS avg_role_length,
    rs.total_actors,
    CASE 
        WHEN rs.total_actors > 10 THEN 'Ensemble Cast'
        WHEN rs.total_actors IS NULL THEN 'No Actors'
        ELSE 'Solo Cast'
    END AS casting_label,
    COALESCE(ROUND(SUM(LENGTH(a.actor_name) * (CASE WHEN a.role_name LIKE '%lead%' THEN 1.5 ELSE 1 END)) / COUNT(a.actor_name), 2), 0) AS weighted_actor_score
FROM 
    movie_details md
LEFT JOIN 
    cast_hierarchy a ON md.movie_id = a.movie_id
LEFT JOIN 
    role_summary rs ON md.movie_id = rs.movie_id
GROUP BY 
    md.movie_id, md.title, md.keyword, md.companies, rs.avg_role_length, rs.total_actors
ORDER BY 
    avg_role_length DESC, total_actors DESC
LIMIT 100;
