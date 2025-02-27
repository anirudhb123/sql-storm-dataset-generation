WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ml.linked_movie_id,
        1 AS depth
    FROM 
        title m
    LEFT JOIN 
        movie_link ml ON m.id = ml.movie_id
    WHERE 
        m.production_year > 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ml.linked_movie_id,
        depth + 1
    FROM 
        title m
    INNER JOIN 
        movie_link ml ON m.id = ml.movie_id
    INNER JOIN 
        movie_hierarchy mh ON mh.linked_movie_id = m.id
)
SELECT 
    t.title AS Movie_Title,
    t.production_year AS Production_Year,
    COALESCE(a.name, 'Unknown Actor') AS Actor_Name,
    COUNT(DISTINCT kh.keyword) AS Total_Keywords,
    AVG(m.profit) AS Average_Profit,
    ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS Rank
FROM 
    title t
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Profit')
LEFT JOIN 
    cast_info ci ON t.id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kh ON mk.keyword_id = kh.id
LEFT JOIN 
    movie_hierarchy mh ON mh.movie_id = t.id
GROUP BY 
    t.id, a.name
HAVING 
    COUNT(DISTINCT kh.keyword) > 3
ORDER BY 
    Production_Year DESC, Average_Profit DESC;

