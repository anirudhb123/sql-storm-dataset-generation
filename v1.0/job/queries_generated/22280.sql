WITH RECURSIVE cte_movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        COALESCE(rl.title, 'No Related Movie') AS related_movie_title
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    LEFT JOIN 
        aka_title rl ON ml.linked_movie_id = rl.id
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        COALESCE(rl.title, 'No Related Movie') AS related_movie_title
    FROM 
        aka_title mt
    JOIN 
        cte_movie_hierarchy ch ON mt.id = ch.movie_id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT ml.linked_movie_id) AS related_movies_count,
    STRING_AGG(DISTINCT rl.related_movie_title, '; ') AS related_movies,
    ROW_NUMBER() OVER(PARTITION BY ak.name ORDER BY at.production_year DESC) AS rn,
    CASE 
        WHEN ak.name IS NULL THEN 'Unknown Actor'
        ELSE ak.name
    END AS actor_display_name,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM movie_keyword mk 
            WHERE mk.movie_id = at.id 
            AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%winner%')
        ) THEN 'Award Winning Movie'
        ELSE 'Regular Movie'
    END AS movie_status
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_link ml ON at.id = ml.movie_id
LEFT JOIN 
    cte_movie_hierarchy rl ON ml.linked_movie_id = rl.movie_id
WHERE 
    ak.name IS NOT NULL
AND 
    (at.production_year < 2000 OR at.production_year > 2010)
AND 
    ak.md5sum IS NOT NULL
GROUP BY 
    ak.name, at.title, at.production_year
HAVING 
    COUNT(DISTINCT ml.linked_movie_id) > 1
ORDER BY 
    rn, at.production_year DESC;
