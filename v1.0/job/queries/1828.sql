WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
actors_count AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
movies_with_actors AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count
    FROM 
        ranked_movies rm
    LEFT JOIN 
        actors_count ac ON rm.movie_id = ac.movie_id
),
filtered_movies AS (
    SELECT 
        mwa.*,
        CASE 
            WHEN actor_count > 5 THEN 'Popular'
            WHEN actor_count = 0 THEN 'No Actors'
            ELSE 'Regular'
        END AS movie_category
    FROM 
        movies_with_actors mwa
    WHERE 
        production_year BETWEEN 2000 AND 2020
)
SELECT 
    f.movie_category,
    COUNT(*) AS movie_count,
    STRING_AGG(f.title, ', ') AS movie_titles
FROM 
    filtered_movies f
GROUP BY 
    f.movie_category
ORDER BY 
    movie_count DESC;
