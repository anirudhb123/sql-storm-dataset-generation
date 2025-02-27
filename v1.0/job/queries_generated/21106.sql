WITH recursive movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COALESCE(links.linked_movie_id, 0) AS linked_movie_id,
        1 AS hierarchy_level
    FROM 
        title m
    LEFT JOIN 
        movie_link links ON m.id = links.movie_id
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id,
        m.title,
        COALESCE(ml.linked_movie_id, 0),
        mh.hierarchy_level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN 
        title m ON ml.linked_movie_id = m.id
)

SELECT 
    p.name AS actor_name,
    t.title AS movie_title,
    CASE
        WHEN COUNT(DISTINCT cm.kind) = 0 THEN 'No Company Info'
        ELSE STRING_AGG(DISTINCT cm.kind, ', ') OVER(PARTITION BY t.id)
    END AS production_companies,
    AVG(mk.keyword_count) AS average_keywords,
    COUNT(DISTINCT mh.linked_movie_id) AS number_of_linked_movies,
    ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY COUNT(DISTINCT mh.linked_movie_id) DESC) AS movie_rank
FROM 
    aka_name p
JOIN 
    cast_info ci ON p.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_type cm ON mc.company_type_id = cm.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    (SELECT movie_id, COUNT(keyword_id) AS keyword_count
     FROM movie_keyword
     GROUP BY movie_id) AS mk ON mk.movie_id = t.id
LEFT JOIN 
    movie_hierarchy mh ON mh.movie_id = t.id
WHERE 
    p.name IS NOT NULL 
    AND p.name NOT LIKE '%unknown%'
    AND t.production_year >= 2000
    AND (t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Sci-Fi%') OR t.kind_id IS NULL)
GROUP BY 
    p.name, t.title
HAVING 
    COUNT(DISTINCT mh.linked_movie_id) > 0
ORDER BY 
    movie_rank ASC, actor_name ASC;
