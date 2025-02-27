WITH ranked_movies AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        t.kind_id, 
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
actor_details AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies_played
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    GROUP BY 
        a.person_id, a.name
),
top_actors AS (
    SELECT 
        ad.name, 
        ad.movie_count,
        ad.movies_played,
        RANK() OVER (ORDER BY ad.movie_count DESC) AS rank
    FROM 
        actor_details ad
    WHERE 
        ad.movie_count > 5
)
SELECT 
    rm.title_id, 
    rm.title, 
    rm.production_year, 
    rm.actor_count, 
    rm.actor_names, 
    ta.name AS top_actor_name,
    ta.movie_count AS top_actor_movies,
    ta.movies_played
FROM 
    ranked_movies rm
LEFT JOIN 
    top_actors ta ON rm.actor_names LIKE '%' || ta.name || '%'
WHERE 
    rm.actor_count > 0
ORDER BY 
    rm.production_year DESC, 
    rm.actor_count DESC;
