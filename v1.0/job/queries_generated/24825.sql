WITH RECURSIVE movie_chain AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS chain_level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        mk.linked_movie_id,
        a.title,
        a.production_year,
        mc.chain_level + 1
    FROM 
        movie_link mk
    JOIN 
        aka_title a ON mk.linked_movie_id = a.id
    JOIN 
        movie_chain mc ON mk.movie_id = mc.movie_id
    WHERE 
        mk.link_type_id IN (SELECT id FROM link_type WHERE link = 'spin-off')
)

SELECT 
    a.name,
    COUNT(DISTINCT ca.movie_id) AS total_movies,
    STRING_AGG(DISTINCT m.title, ', ') AS movie_titles,
    MAX(CASE WHEN m.production_year IS NOT NULL THEN m.production_year ELSE 2023 END) AS recent_production_year,
    ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY COUNT(DISTINCT ca.movie_id) DESC) AS rank
FROM 
    aka_name a
LEFT JOIN 
    cast_info ca ON a.person_id = ca.person_id
LEFT JOIN 
    movie_chain mc ON ca.movie_id = mc.movie_id
LEFT JOIN 
    aka_title m ON mc.movie_id = m.id
WHERE 
    a.name IS NOT NULL
    AND a.name NOT LIKE '%uncredited%'
    AND (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = ca.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'box office')) > 0
GROUP BY 
    a.id, a.name
HAVING 
    COUNT(DISTINCT ca.movie_id) > 1
ORDER BY 
    total_movies DESC, a.name;

-- This query creates a recursive CTE to explore a chain of movies that are spin-offs,
-- calculates the total number of movies per actor, aggregates those movie titles,
-- derives the most recent production year while using obscure NULL handling,
-- and ranks the results based on the number of films each actor has taken part in.
