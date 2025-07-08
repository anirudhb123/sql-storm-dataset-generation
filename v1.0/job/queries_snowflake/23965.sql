
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
movie_actors AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(c.person_id) AS actor_count
    FROM 
        cast_info c
        JOIN aka_name a ON c.person_id = a.person_id
    WHERE 
        c.role_id IS NOT NULL
    GROUP BY 
        c.movie_id, a.name
),
top_movies AS (
    SELECT 
        mm.movie_id,
        mm.title,
        mm.production_year,
        ma.actor_name,
        ma.actor_count,
        RANK() OVER (ORDER BY mm.production_year DESC, ma.actor_count DESC) AS movie_rank
    FROM 
        ranked_movies mm
    JOIN 
        movie_actors ma ON mm.movie_id = ma.movie_id
),
highlights AS (
    SELECT 
        tm.movie_id,
        MAX(tm.actor_count) AS max_actor_count,
        LISTAGG(DISTINCT tm.actor_name, ', ') AS all_actors
    FROM 
        top_movies tm
    WHERE 
        tm.movie_rank <= 10
    GROUP BY 
        tm.movie_id
)
SELECT 
    h.movie_id,
    h.max_actor_count,
    h.all_actors,
    CASE 
        WHEN h.max_actor_count > 5 THEN 'Star-studded'
        WHEN h.max_actor_count BETWEEN 3 AND 5 THEN 'Moderately Cast'
        ELSE 'Minimal Cast'
    END AS cast_description,
    COALESCE(i.info, 'No additional info available') AS additional_info
FROM 
    highlights h
LEFT JOIN 
    movie_info i ON h.movie_id = i.movie_id AND i.info_type_id = (SELECT id FROM info_type WHERE info = 'Awards' LIMIT 1)
WHERE 
    EXISTS (SELECT 1 FROM movie_keyword mk WHERE mk.movie_id = h.movie_id AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%Award%'))
ORDER BY 
    h.max_actor_count DESC, 
    h.movie_id ASC;
