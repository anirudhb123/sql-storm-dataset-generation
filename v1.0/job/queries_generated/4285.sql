WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.name) AS cast_names,
        COUNT(DISTINCT m.company_id) AS company_count,
        AVG(CASE WHEN m.company_type_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_company_type_exists
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info cinfo ON cc.subject_id = cinfo.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    LEFT JOIN 
        movie_companies m ON t.id = m.movie_id
    GROUP BY 
        t.id
),
highly_rated_movies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_names,
        CASE 
            WHEN md.company_count > 5 THEN 'High'
            ELSE 'Medium or Low'
        END AS company_rating
    FROM 
        movie_details md
    WHERE 
        md.production_year >= 2000
),
actor_info AS (
    SELECT 
        ak.person_id,
        ak.name,
        COUNT(DISTINCT ci.movie_id) AS movies_count,
        MAX(ci.nr_order) AS highest_role_order
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.person_id, ak.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 3
),
final_output AS (
    SELECT 
        hr.movie_id,
        hr.title,
        hr.production_year,
        hr.cast_names,
        ai.name AS lead_actor,
        ai.movies_count,
        ai.highest_role_order,
        hr.company_rating
    FROM 
        highly_rated_movies hr
    LEFT JOIN 
        actor_info ai ON hr.cast_names LIKE CONCAT('%', ai.name, '%')
)
SELECT 
    movie_id,
    title,
    production_year,
    COALESCE(lead_actor, 'Unknown') AS lead_actor,
    movies_count,
    highest_role_order,
    company_rating
FROM 
    final_output
ORDER BY 
    production_year DESC, 
    company_rating DESC, 
    highest_role_order DESC;
