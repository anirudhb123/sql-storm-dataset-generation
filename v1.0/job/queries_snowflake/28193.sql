
WITH actor_movies AS (
    SELECT 
        ak.person_id,
        ak.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        at.kind_id,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY at.production_year DESC) AS movie_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.id
),
actor_movie_counts AS (
    SELECT 
        person_id,
        COUNT(*) AS movie_count
    FROM 
        actor_movies
    GROUP BY 
        person_id
),
top_actors AS (
    SELECT 
        am.actor_name,
        am.movie_title,
        am.production_year,
        am.kind_id,
        ac.movie_count
    FROM 
        actor_movies am
    JOIN 
        actor_movie_counts ac ON am.person_id = ac.person_id
    WHERE 
        am.movie_rank <= 5
    ORDER BY 
        ac.movie_count DESC, am.production_year DESC
)
SELECT 
    ta.actor_name,
    LISTAGG(ta.movie_title || ' (' || ta.production_year || ')', ', ') AS movies,
    ta.movie_count
FROM 
    top_actors ta
GROUP BY 
    ta.actor_name, ta.movie_count
ORDER BY 
    ta.movie_count DESC;
