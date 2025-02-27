WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        m.linked_movie_id,
        1 AS level
    FROM 
        title mt
    LEFT JOIN 
        movie_link m ON mt.id = m.movie_id
    WHERE 
        mt.production_year > 2000
    
    UNION ALL
    
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        m.linked_movie_id,
        mh.level + 1
    FROM 
        title mt
    INNER JOIN 
        movie_link m ON mt.id = m.linked_movie_id
    INNER JOIN 
        movie_hierarchy mh ON mh.movie_id = m.movie_id
)

SELECT
    ak.name AS actor_name,
    t.title AS movie_title,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    ARRAY_AGG(DISTINCT mh.title) AS linked_movies,
    AVG(CASE 
        WHEN YEAR(CURRENT_DATE) - t.production_year > 10 THEN 1 
        ELSE NULL 
    END) AS avg_age_of_movies,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS actor_rank,
    COALESCE(ci.note, 'No note available') AS casting_note
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    aka_title at ON c.movie_id = at.movie_id
JOIN 
    title t ON at.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_hierarchy mh ON t.id = mh.movie_id
LEFT JOIN 
    complete_cast cc ON t.id = cc.movie_id
LEFT JOIN 
    comp_cast_type cc_type ON c.role_id = cc_type.id
LEFT JOIN 
    company_name cp ON cp.id = (SELECT mc.company_id 
                                FROM movie_companies mc 
                                WHERE mc.movie_id = t.id LIMIT 1)
GROUP BY 
    ak.name, t.title, ci.note
HAVING
    COUNT(DISTINCT c.movie_id) > 5
ORDER BY
    total_movies DESC, actor_name
LIMIT 50;
