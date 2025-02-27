WITH RECURSIVE movie_chain AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
    
    UNION ALL
    
    SELECT 
        mt.linked_movie_id AS movie_id,
        m.title,
        mc.depth + 1 AS depth
    FROM 
        movie_link mt
    JOIN 
        movie_chain mc ON mt.movie_id = mc.movie_id
    JOIN 
        aka_title m ON mt.linked_movie_id = m.id
    WHERE 
        mc.depth < 5  -- limit the recursion to 5 "links" deep
)

SELECT 
    ak.name AS actor_name,
    string_agg(DISTINCT kt.keyword, ', ') AS keywords,
    wc.production_year,
    wc.title,
    wc.depth,
    COUNT(DISTINCT cc.movie_id) AS total_movies,
    ROUND(AVG(mv.length), 2) AS avg_length,
    MAX(wc.production_year) AS latest_year,
    CASE 
        WHEN COUNT(DISTINCT cc.movie_id) > 10 THEN 'Prolific Actor'
        WHEN COUNT(DISTINCT cc.movie_id) = 0 THEN 'Not Active'
        ELSE 'Occasionally Active'
    END AS activity_type
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id 
LEFT JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id 
LEFT JOIN 
    aka_title wc ON mc.movie_id = wc.id
LEFT JOIN 
    movie_keyword mk ON wc.id = mk.movie_id
LEFT JOIN 
    keyword kt ON mk.keyword_id = kt.id
LEFT JOIN 
    complete_cast cc ON wc.id = cc.movie_id

LEFT JOIN 
(
    SELECT 
        m.id, 
        LENGTH(m.title) AS length
    FROM 
        aka_title m
) mv ON wc.id = mv.id 

WHERE 
    (ak.name IS NOT NULL AND ak.name <> '') 
    AND (wc.production_year IS NOT NULL OR wc.production_year > 0)
    AND (wc.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'M%') OR wc.kind_id IS NULL)
    
GROUP BY 
    ak.name, wc.id, wc.title, wc.production_year, mc.movie_id, wc.depth
ORDER BY 
    total_movies DESC,
    avg_length ASC
LIMIT 100;
