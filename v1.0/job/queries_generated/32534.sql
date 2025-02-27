WITH RECURSIVE cte_movies AS (
    SELECT 
        mt.movie_id, 
        t.title,
        1 AS level
    FROM 
        title AS t 
    JOIN 
        aka_title AS mt ON t.id = mt.movie_id
    WHERE 
        t.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.movie_id, 
        t.title,
        cm.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        cte_movies AS cm ON ml.movie_id = cm.movie_id
    JOIN 
        title AS t ON ml.linked_movie_id = t.id
)

SELECT 
    m.title, 
    a.name AS actor_name,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    AVG(CASE WHEN pi.info_type_id = 1 THEN CAST(pi.info AS FLOAT) END) AS avg_rating,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS actor_count
FROM 
    cte_movies AS m
LEFT JOIN 
    cast_info AS ci ON m.movie_id = ci.movie_id
LEFT JOIN 
    aka_name AS a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_companies AS mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    movie_info AS mi ON m.movie_id = mi.movie_id
LEFT JOIN 
    person_info AS pi ON ci.person_id = pi.person_id 
LEFT JOIN 
    movie_keyword AS mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword AS kw ON mk.keyword_id = kw.id
WHERE 
    a.name IS NOT NULL
    AND (mi.info_type_id IS NULL OR mi.info_type_id != 2)
GROUP BY 
    m.title, a.name
HAVING 
    COUNT(DISTINCT mc.company_id) > 5 AND 
    AVG(CASE WHEN pi.info_type_id = 1 THEN CAST(pi.info AS FLOAT) END) IS NOT NULL
ORDER BY 
    actor_count DESC, 
    m.title;
