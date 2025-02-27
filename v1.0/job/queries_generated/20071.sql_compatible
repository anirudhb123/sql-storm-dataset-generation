
WITH 

movies_produced_2020 AS (
    SELECT 
        id AS movie_id, 
        title, 
        production_year 
    FROM 
        aka_title 
    WHERE 
        production_year = 2020
),

actor_roles AS (
    SELECT 
        c.movie_id, 
        COALESCE(STRING_AGG(DISTINCT r.role, ', '), 'No role') AS roles,
        COUNT(c.person_id) AS actor_count 
    FROM 
        cast_info c
    LEFT JOIN 
        role_type r ON c.role_id = r.id 
    WHERE 
        c.movie_id IN (SELECT movie_id FROM movies_produced_2020)
    GROUP BY 
        c.movie_id
),

movie_company_links AS (
    SELECT 
        m.movie_id, 
        STRING_AGG(DISTINCT cn.name, ', ') AS companies 
    FROM 
        movie_companies m
    JOIN 
        company_name cn ON m.company_id = cn.id 
    GROUP BY 
        m.movie_id
),

movie_general_info AS (
    SELECT 
        mi.movie_id,
        COALESCE(STRING_AGG(DISTINCT mi.info), 'No info') AS info 
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
),

ranked_movies AS (
    SELECT 
        mp.movie_id, 
        mp.title, 
        mp.production_year, 
        ar.roles, 
        ar.actor_count,
        mc.companies, 
        mg.info,
        RANK() OVER (ORDER BY ar.actor_count DESC, mp.title) AS rank 
    FROM 
        movies_produced_2020 mp
    LEFT JOIN 
        actor_roles ar ON mp.movie_id = ar.movie_id
    LEFT JOIN 
        movie_company_links mc ON mp.movie_id = mc.movie_id
    LEFT JOIN 
        movie_general_info mg ON mp.movie_id = mg.movie_id
)

SELECT 
    movie_id, 
    title, 
    production_year, 
    roles,
    actor_count, 
    companies, 
    info,
    CASE 
        WHEN info = 'No info' THEN 'Information not available' 
        ELSE 'Information available' 
    END AS info_status
FROM 
    ranked_movies
WHERE 
    rank <= 10
ORDER BY 
    rank;
