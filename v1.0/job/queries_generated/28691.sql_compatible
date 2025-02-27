
WITH actor_movie_count AS (
    SELECT 
        ak.person_id, 
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.person_id
),
top_actors AS (
    SELECT 
        ak.id AS actor_id, 
        ak.name, 
        amc.movie_count
    FROM 
        aka_name ak
    JOIN 
        actor_movie_count amc ON ak.person_id = amc.person_id
    WHERE 
        amc.movie_count > 5  
    ORDER BY 
        amc.movie_count DESC
    LIMIT 10
),
movie_details AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(ci.person_id) >= 3  
),
actor_movie_info AS (
    SELECT 
        ta.name AS actor_name, 
        md.title AS movie_title, 
        md.production_year, 
        md.cast_count
    FROM 
        top_actors ta
    JOIN 
        cast_info ci ON ta.actor_id = ci.person_id
    JOIN 
        movie_details md ON ci.movie_id = md.movie_id
)
SELECT 
    actor_name, 
    movie_title, 
    production_year, 
    cast_count
FROM 
    actor_movie_info
ORDER BY 
    production_year DESC, 
    actor_name;
