WITH RECURSIVE movie_recursion AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year > 2000

    UNION ALL

    SELECT 
        m2.id AS movie_id,
        m2.title AS movie_title,
        m2.production_year,
        level + 1
    FROM 
        aka_title m2
    INNER JOIN 
        movie_recursion mr ON m2.episode_of_id = mr.movie_id
)

SELECT 
    ak.name AS actor_name,
    mt.movie_title,
    mt.production_year,
    COUNT(DISTINCT kw.keyword) AS keyword_count,
    AVG(pi.info) FILTER (WHERE pi.info_type_id = 2) AS average_actor_info,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY mt.production_year DESC) AS role_rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    movie_recursion mt ON ci.movie_id = mt.movie_id
LEFT JOIN 
    movie_keyword mk ON mt.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id
WHERE 
    ak.name IS NOT NULL 
    AND ak.name != ''
    AND mt.production_year IS NOT NULL
GROUP BY 
    ak.person_id,
    ak.name,
    mt.movie_title,
    mt.production_year
HAVING 
    COUNT(DISTINCT kw.keyword) > 5
ORDER BY 
    average_actor_info DESC, 
    role_rank;
