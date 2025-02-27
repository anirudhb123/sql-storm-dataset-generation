WITH movie_actors AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.role_id) AS total_roles
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    WHERE 
        a.name IS NOT NULL AND 
        t.production_year >= 2000
    GROUP BY 
        a.id, a.name, c.movie_id, t.title, t.production_year
),

high_role_actors AS (
    SELECT 
        actor_id,
        actor_name,
        movie_id,
        title,
        production_year,
        total_roles
    FROM 
        movie_actors
    WHERE 
        total_roles > 2
),

actor_movie_info AS (
    SELECT 
        h.actor_id,
        h.actor_name,
        h.movie_id,
        h.title,
        h.production_year,
        mii.info AS movie_info,
        mi.note AS movie_note
    FROM 
        high_role_actors h
    LEFT JOIN 
        movie_info mi ON h.movie_id = mi.movie_id
    LEFT JOIN 
        movie_info_idx mii ON h.movie_id = mii.movie_id
)

SELECT 
    actor_name,
    COUNT(DISTINCT movie_id) AS movie_count,
    STRING_AGG(DISTINCT title, ', ') AS movie_titles,
    STRING_AGG(DISTINCT movie_info, ', ') AS additional_info,
    STRING_AGG(DISTINCT movie_note, ', ') AS notes
FROM 
    actor_movie_info
GROUP BY 
    actor_name
ORDER BY 
    movie_count DESC;
