WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_movie_count AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    GROUP BY 
        c.person_id
),
movie_details AS (
    SELECT 
        rm.title,
        rm.production_year,
        COALESCE(cm.name, 'Unknown') AS company_name,
        COALESCE(agg_actor.actor_count, 0) AS total_actors,
        rm.total_movies
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cm ON mc.company_id = cm.id
    LEFT JOIN (
        SELECT 
            c.movie_id, 
            COUNT(DISTINCT c.person_id) AS actor_count
        FROM 
            cast_info c
        GROUP BY 
            c.movie_id
    ) agg_actor ON rm.movie_id = agg_actor.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.company_name,
    md.total_actors,
    CASE 
        WHEN md.total_actors IS NULL THEN 'No actors'
        WHEN md.total_actors > 10 THEN 'Blockbuster'
        ELSE 'Indie Film'
    END AS film_type,
    COALESCE(md.total_movies, 0) AS total_movies_in_year,
    RANK() OVER (ORDER BY md.total_actors DESC) AS actor_rank
FROM 
    movie_details md
LEFT JOIN 
    actor_movie_count amc ON md.total_actors = amc.movie_count
WHERE 
    md.production_year BETWEEN 2000 AND 2020
ORDER BY 
    md.production_year DESC, md.total_actors DESC;
