WITH movie_cast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
), 
movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(m.movie_id) AS total_companies,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies m ON t.id = m.movie_id
    LEFT JOIN 
        company_name cn ON m.company_id = cn.id
    GROUP BY 
        t.id
),
actor_movie_info AS (
    SELECT 
        mc.movie_id,
        mc.actor_name,
        md.title,
        md.production_year,
        CASE 
            WHEN md.total_companies > 0 THEN md.company_names 
            ELSE 'No Companies' 
        END AS companies_info
    FROM 
        movie_cast mc
    JOIN 
        movie_details md ON mc.movie_id = md.title_id
)

SELECT 
    ami.actor_name,
    ami.title,
    ami.production_year,
    ami.companies_info,
    MAX(CASE WHEN ami.production_year IS NOT NULL THEN 'Has Year' ELSE 'No Year' END) AS production_year_status,
    COUNT(DISTINCT ami.movie_id) OVER (PARTITION BY ami.actor_name) AS movie_count
FROM 
    actor_movie_info ami
WHERE 
    ami.actor_name NOT LIKE '%[0-9]%'  -- Actors whose names do not contain digits
    AND ami.actor_order <= 5           -- Limiting to top 5 actors per movie
ORDER BY 
    ami.actor_name, 
    ami.production_year DESC NULLS LAST;

This SQL query performs the following tasks:
1. Generates a CTE (`movie_cast`) to gather movie IDs, actor names, and their order in cast lists.
2. Produces another CTE (`movie_details`) to get movie titles, production years, and the names of companies associated with each movie, aggregating them.
3. Combines these to form `actor_movie_info`, which includes the information about actors, movies they've been in, and company details.
4. In the final selection, the query extracts and conditions on various metrics such as the presence of digits in actor names, limits the number of actors returned per movie, and manages overall output formatting including NULL handling.
5. Uses window functions for counting distinct movies for each actor and checks conditions to create new derived columns.
