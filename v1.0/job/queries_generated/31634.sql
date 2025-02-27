WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        c.id AS cast_info_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        cast_info ci
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    WHERE 
        ci.nr_order = 1   -- Starting with lead actors

    UNION ALL

    SELECT 
        ci.person_id,
        ci.id AS cast_info_id,
        t.title,
        t.production_year,
        ah.level + 1
    FROM 
        cast_info ci
    JOIN 
        ActorHierarchy ah ON ci.movie_id = ah.cast_info_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
)

SELECT 
    ak.name AS actor_name,
    t.title AS movie_title,
    ah.production_year,
    COALESCE(active_credits.total_credits, 0) AS total_active_credits,
    COALESCE(prev_year_credits.total_prev_year_credits, 0) AS total_prev_year_credits
FROM 
    ActorHierarchy ah
JOIN 
    aka_name ak ON ah.person_id = ak.person_id
JOIN 
    title t ON ah.title = t.title AND ah.production_year = t.production_year
LEFT JOIN (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS total_credits
    FROM 
        cast_info ci
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    WHERE 
        at.production_year = EXTRACT(YEAR FROM CURRENT_DATE) -- Current year
    GROUP BY 
        ci.person_id
) active_credits ON ak.person_id = active_credits.person_id
LEFT JOIN (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS total_prev_year_credits
    FROM 
        cast_info ci
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    WHERE 
        at.production_year = EXTRACT(YEAR FROM CURRENT_DATE) - 1 -- Previous year
    GROUP BY 
        ci.person_id
) prev_year_credits ON ak.person_id = prev_year_credits.person_id
WHERE 
    ah.level = 1 -- Consider only lead actors
ORDER BY 
    total_active_credits DESC, total_prev_year_credits DESC
LIMIT 10;

This SQL query performs the following tasks:

- It uses a recursive CTE to establish a hierarchy of actors who played in movies.
- It retrieves lead actors along with the titles of their movies and their production years.
- It employs outer joins and subqueries to compute and fetch the total number of active credits for the current year and the previous year for each actor.
- The results are ordered by active credits and limited to the top 10 actors.
