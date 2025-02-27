WITH RECURSIVE MovieChain AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS depth
    FROM 
        aka_title m
    WHERE
        m.production_year BETWEEN 2000 AND 2020
    
    UNION ALL
    
    SELECT 
        mc.linked_movie_id AS movie_id,
        a.title,
        a.production_year,
        depth + 1
    FROM 
        MovieChain mc
    JOIN 
        movie_link ml ON mc.movie_id = ml.movie_id
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    WHERE 
        mc.depth < 3  -- Limit the chain depth to 3
)

SELECT 
    mv.title,
    mv.production_year,
    COUNT(DISTINCT ca.person_id) AS total_actors,
    STRING_AGG(DISTINCT ka.keyword, ', ') AS keywords,
    MAX(CASE WHEN ci.role_id = 1 THEN ca.note END) AS lead_actor_note,
    AVG(mv.production_year) OVER (PARTITION BY mv.production_year) AS avg_year,
    SUM(CASE WHEN mv.note IS NULL THEN 1 ELSE 0 END) AS null_note_count
FROM 
    MovieChain mv
LEFT JOIN 
    complete_cast cc ON mv.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ca ON cc.subject_id = ca.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mv.movie_id
LEFT JOIN 
    keyword ka ON mk.keyword_id = ka.id
LEFT JOIN 
    aka_title at ON mv.movie_id = at.id
GROUP BY 
    mv.movie_id, mv.title, mv.production_year
HAVING 
    COUNT(DISTINCT ca.person_id) > 5
ORDER BY 
    mv.production_year DESC, total_actors DESC;
