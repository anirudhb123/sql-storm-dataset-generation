
WITH movie_actors AS (
    SELECT 
        c.movie_id,
        a.person_id,
        a.name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_order,
        COALESCE(NULLIF(a.name, ''), 'Unknown Actor') AS display_name
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
),

movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        kt.kind AS genre,
        (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = m.id) AS keyword_count,
        (SELECT LISTAGG(k.keyword, ', ') 
         FROM movie_keyword mk 
         JOIN keyword k ON mk.keyword_id = k.id 
         WHERE mk.movie_id = m.id) AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        kind_type kt ON m.kind_id = kt.id
)

SELECT 
    md.title,
    md.production_year,
    md.genre,
    md.keyword_count,
    md.keywords,
    COUNT(DISTINCT ma.person_id) AS actor_count,
    LISTAGG(DISTINCT ma.display_name, ', ') AS actors_list,
    AVG(ma.actor_order) AS avg_actor_order,
    MAX(CASE WHEN ma.actor_order = 1 THEN ma.display_name END) AS first_actor
FROM 
    movie_details md
LEFT JOIN 
    movie_actors ma ON md.movie_id = ma.movie_id
WHERE 
    md.production_year IS NOT NULL 
    AND md.genre IS NOT NULL 
    AND (md.keyword_count > 3 OR md.production_year < 2000)
GROUP BY 
    md.movie_id, md.title, md.production_year, md.genre, md.keywords, md.keyword_count
HAVING 
    COUNT(ma.person_id) > 0
ORDER BY 
    avg_actor_order DESC,
    md.production_year DESC
LIMIT 50;
