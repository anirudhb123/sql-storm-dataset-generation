WITH RECURSIVE MoviePaths AS (
    SELECT 
        m.id AS movie_id,
        ARRAY[m.title] AS title_path,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        mp.movie_id AS movie_id,
        mp.title_path || m.title AS title_path,
        mp.depth + 1 AS depth
    FROM 
        MoviePaths mp
    JOIN 
        movie_link ml ON mp.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        mp.depth < 5
)

SELECT 
    ak.name AS actor_name,
    m.title AS movie_title,
    COUNT(DISTINCT c.id) AS total_characters,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    MAX(mp.depth) AS max_link_depth,
    ARRAY_AGG(DISTINCT mp.title_path) AS linked_movies
FROM 
    cast_info c
JOIN 
    aka_name ak ON c.person_id = ak.person_id
JOIN 
    aka_title m ON c.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    MoviePaths mp ON m.id = mp.movie_id
WHERE 
    ak.name ILIKE '%Smith%' 
    AND m.production_year > 2000
GROUP BY 
    ak.name, m.title
ORDER BY 
    total_characters DESC, max_link_depth DESC
LIMIT 50;
