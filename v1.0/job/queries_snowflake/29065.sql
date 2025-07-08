
WITH movie_credits AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        c.person_id,
        ak.name AS actor_name,
        r.role AS role_name,
        m.production_year
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        m.production_year >= 2000 
),
actor_statistics AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_id) AS movies_count,
        LISTAGG(title, ', ') WITHIN GROUP (ORDER BY title) AS movies_list,
        MIN(production_year) AS first_appearance,
        MAX(production_year) AS last_appearance
    FROM 
        movie_credits
    GROUP BY 
        actor_name
),
most_active_actors AS (
    SELECT 
        actor_name,
        movies_count,
        movies_list,
        first_appearance,
        last_appearance,
        ROW_NUMBER() OVER (ORDER BY movies_count DESC) AS rank
    FROM 
        actor_statistics
)

SELECT 
    rank,
    actor_name,
    movies_count,
    movies_list,
    first_appearance,
    last_appearance
FROM 
    most_active_actors
WHERE 
    rank <= 10 
ORDER BY 
    rank;
