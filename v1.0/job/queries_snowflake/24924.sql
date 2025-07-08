
WITH movie_actors AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        c.nr_order,
        RANK() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
top_movies AS (
    SELECT 
        movie_title,
        production_year,
        COUNT(actor_name) AS actor_count
    FROM 
        movie_actors
    WHERE 
        actor_rank <= 5  
    GROUP BY 
        movie_title, 
        production_year
    HAVING 
        COUNT(actor_name) >= 3  
),
actor_movies AS (
    SELECT 
        ma.actor_name, 
        ma.movie_title,
        ma.production_year,
        CASE 
            WHEN tm.actor_count IS NOT NULL THEN 'Top Movie'
            ELSE 'Other Movie'
        END AS movie_type,
        ROW_NUMBER() OVER (PARTITION BY ma.actor_name ORDER BY ma.production_year DESC) AS movie_order
    FROM 
        movie_actors ma
    LEFT JOIN 
        top_movies tm ON ma.movie_title = tm.movie_title AND ma.production_year = tm.production_year
),
final_actor_stats AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_title) AS total_movies,
        AVG(production_year) AS avg_production_year,
        LISTAGG(DISTINCT movie_type, ', ') WITHIN GROUP (ORDER BY movie_type) AS movie_category,
        SUM(CASE WHEN movie_order = 1 THEN 1 ELSE 0 END) AS latest_movie_flag
    FROM 
        actor_movies
    GROUP BY 
        actor_name
)

SELECT
    actor_name,
    total_movies,
    avg_production_year,
    movie_category,
    CASE 
        WHEN latest_movie_flag > 0 THEN 'Yes'
        ELSE 'No'
    END AS has_latest_movie
FROM 
    final_actor_stats
WHERE 
    total_movies > 1  
ORDER BY 
    total_movies DESC, 
    avg_production_year DESC;
