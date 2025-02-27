WITH RECURSIVE movie_chain AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year,
        1 AS depth
    FROM 
        aka_title AS t
    WHERE 
        t.production_year >= 2000
        AND t.title IS NOT NULL
    UNION ALL
    SELECT 
        mc.linked_movie_id AS movie_id, 
        t.title, 
        t.production_year,
        depth + 1
    FROM 
        movie_link AS mc
    JOIN 
        aka_title AS t ON mc.linked_movie_id = t.id
    JOIN 
        movie_chain AS c ON mc.movie_id = c.movie_id
    WHERE 
        t.production_year >= 2000
)
SELECT 
    coalesce(ak.name, ch.name) AS full_name,
    title.title,
    title.production_year,
    COUNT(DISTINCT cast.person_id) OVER(PARTITION BY title.id) AS actor_count,
    RANK() OVER (PARTITION BY title.id ORDER BY COUNT(DISTINCT cast.person_id) DESC) AS ranking,
    CASE 
        WHEN mc.depth IS NULL THEN 'Standalone'
        ELSE 'Connected'
    END AS connection_type
FROM 
    movie_chain AS mc
JOIN 
    title ON mc.movie_id = title.id
LEFT JOIN 
    cast_info AS cast ON cast.movie_id = mc.movie_id
LEFT JOIN 
    aka_name AS ak ON cast.person_id = ak.person_id
LEFT JOIN 
    char_name AS ch ON ak.person_id = ch.imdb_id
WHERE 
    (title.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'Feature%'))
    AND (title.production_year IS NOT NULL OR title.production_year > 1990)
GROUP BY 
    full_name, title.id, mc.depth
HAVING 
    COUNT(DISTINCT cast.person_id) > 1
ORDER BY 
    RANK() DESC, title.production_year DESC
LIMIT 50;
