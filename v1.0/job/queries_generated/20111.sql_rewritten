WITH RECURSIVE movie_actors AS (
    SELECT 
        ca.movie_id,
        ka.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ca.movie_id ORDER BY ka.name) AS actor_rank
    FROM 
        cast_info ca
    JOIN 
        aka_name ka ON ca.person_id = ka.person_id
    WHERE 
        ka.name IS NOT NULL
),
actor_movies AS (
    SELECT 
        ma.movie_id,
        COUNT(ma.actor_name) AS num_actors,
        STRING_AGG(ma.actor_name, ', ') AS actors_list
    FROM 
        movie_actors ma
    GROUP BY 
        ma.movie_id
),
selected_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword
    FROM 
        title t
    JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    JOIN 
        keyword k ON k.id = mk.keyword_id
    WHERE 
        k.keyword LIKE 'Action%' OR k.keyword IS NULL
),
combined_data AS (
    SELECT 
        t.title,
        t.production_year,
        am.num_actors,
        am.actors_list,
        CASE 
            WHEN am.num_actors IS NULL THEN 'No Cast'
            ELSE 'Cast Available'
        END AS cast_status
    FROM 
        selected_titles t
    LEFT JOIN 
        actor_movies am ON t.title_id = am.movie_id
)
SELECT 
    cd.title,
    cd.production_year,
    cd.num_actors,
    cd.actors_list,
    CASE 
        WHEN cd.num_actors < 5 THEN 'Low Actor Count'
        WHEN cd.num_actors BETWEEN 5 AND 10 THEN 'Moderate Actor Count'
        ELSE 'High Actor Count'
    END AS actor_count_category
FROM 
    combined_data cd
WHERE 
    cd.cast_status = 'Cast Available'
ORDER BY 
    cd.production_year DESC, 
    cd.num_actors DESC
LIMIT 10;