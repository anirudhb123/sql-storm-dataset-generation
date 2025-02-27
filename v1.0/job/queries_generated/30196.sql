WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title AS mt 
    WHERE 
        mt.production_year > 2000  -- selecting movies produced after the year 2000
    
    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 3  -- limit the depth of recursion
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    ARRAY_AGG(DISTINCT mt.title ORDER BY mt.production_year) AS movie_titles,
    AVG(CASE 
        WHEN m.production_year IS NOT NULL THEN m.production_year
        ELSE NULL
    END) AS average_production_year,
    MAX(m.production_year) AS latest_movie,
    STRING_AGG(k.keyword, ', ') AS keywords,
    nt.name AS company_name,
    p.info AS person_info
FROM 
    aka_name AS a
JOIN 
    cast_info AS c ON a.person_id = c.person_id
JOIN 
    movie_hierarchy AS m ON c.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword AS mk ON mk.movie_id = m.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies AS mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_name AS nt ON mc.company_id = nt.id
LEFT JOIN 
    person_info AS p ON a.person_id = p.person_id 
WHERE 
    a.name IS NOT NULL 
    AND (p.info IS NULL OR p.info NOT LIKE '%actor%')  -- specific Predicate
GROUP BY 
    a.name, nt.name, p.info
HAVING 
    COUNT(DISTINCT c.movie_id) > 5  -- filtering for actors with more than 5 movies
ORDER BY 
    total_movies DESC, a.name;


