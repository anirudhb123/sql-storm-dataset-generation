
WITH movie_cast AS (
    SELECT 
        c.movie_id,
        STRING_AGG(a.name, ', ') AS actor_names,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
movie_genre AS (
    SELECT 
        m.id AS movie_id,
        k.keyword AS genre
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
movie_info_data AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, ', ') AS info_details
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
),
summary AS (
    SELECT 
        mt.title AS movie_title,
        mc.actor_names,
        mc.actor_count,
        mg.genre,
        mi.info_details
    FROM 
        movie_cast mc
    JOIN 
        aka_title mt ON mc.movie_id = mt.id
    LEFT JOIN 
        movie_genre mg ON mc.movie_id = mg.movie_id
    LEFT JOIN 
        movie_info_data mi ON mc.movie_id = mi.movie_id
)
SELECT 
    movie_title,
    actor_names,
    actor_count,
    STRING_AGG(DISTINCT genre, ', ') AS genres,
    info_details
FROM 
    summary
GROUP BY 
    movie_title, actor_names, actor_count, info_details
ORDER BY 
    actor_count DESC, movie_title;
