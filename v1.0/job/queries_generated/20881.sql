WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        ca.movie_id,
        ca.role_id,
        1 AS level
    FROM 
        aka_name a
    JOIN 
        cast_info ca ON a.person_id = ca.person_id
    WHERE 
        a.name LIKE '%Smith%'  -- Filtering for actors with 'Smith' in their names
    UNION ALL
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        ci.movie_id,
        ci.role_id,
        ah.level + 1
    FROM 
        actor_hierarchy ah
    JOIN 
        cast_info ci ON ah.movie_id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ah.level < 5  -- Limit the recursion to 5 levels deep
),
movie_details AS (
    SELECT 
        at.title,
        at.production_year,
        at.id AS movie_id,
        STRING_AGG(DISTINCT an.name, ', ') AS actors
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.title, at.production_year, at.id
),
ranked_movies AS (
    SELECT 
        md.title,
        md.production_year,
        COUNT(ah.actor_id) AS actor_count,
        DENSE_RANK() OVER (ORDER BY COUNT(ah.actor_id) DESC) AS rank
    FROM 
        movie_details md
    LEFT JOIN 
        actor_hierarchy ah ON md.movie_id = ah.movie_id
    GROUP BY 
        md.title, md.production_year
)
SELECT 
    rm.rank,
    rm.title,
    rm.production_year,
    COALESCE(md.actors, 'No actors') AS actors_list,
    CASE 
        WHEN rm.actor_count > 5 THEN 'High actor count'
        WHEN rm.actor_count > 0 THEN 'Medium actor count'
        ELSE 'No actors'
    END AS actor_count_category
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_details md ON rm.title = md.title AND rm.production_year = md.production_year
WHERE 
    rm.rank <= 10  -- Limit the output to top 10 movies
ORDER BY 
    rm.rank;
