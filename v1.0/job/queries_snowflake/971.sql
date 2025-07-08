
WITH ranked_movies AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
merged_info AS (
    SELECT 
        rm.actor_name,
        rm.movie_title,
        rm.production_year,
        COALESCE(CAST(mi.info AS STRING), 'No Info Available') AS movie_info,
        ROW_NUMBER() OVER (PARTITION BY rm.actor_name ORDER BY rm.production_year DESC) AS info_rn
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_info mi ON rm.movie_title = mi.info
    WHERE 
        rm.rn <= 5
),
distinct_movies AS (
    SELECT DISTINCT 
        actor_name, 
        movie_title, 
        production_year, 
        movie_info 
    FROM 
        merged_info 
    WHERE 
        production_year >= 1990
)
SELECT 
    actor_name,
    LISTAGG(movie_title || ' (' || production_year || ')', ', ') WITHIN GROUP (ORDER BY production_year DESC) AS movie_list,
    COUNT(*) AS movie_count,
    MIN(production_year) AS first_year,
    MAX(production_year) AS last_year
FROM 
    distinct_movies
GROUP BY 
    actor_name
HAVING 
    COUNT(*) > 3
ORDER BY 
    movie_count DESC;
