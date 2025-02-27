WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        CONCAT('Sequel to: ', mh.title) AS title,
        mh.production_year + 1 AS production_year,
        mh.depth + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        aka_title m ON m.episode_of_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS num_movies,
    AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE 0 END) AS avg_order,
    LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
    COUNT(DISTINCT mh.movie_id) FILTER (WHERE mh.depth <= 2) AS sequels_count
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
LEFT JOIN 
    movie_keyword mk ON c.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
WHERE 
    ak.name IS NOT NULL AND ak.name <> 'Unknown'
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 10
ORDER BY 
    num_movies DESC,
    avg_order DESC
LIMIT 5;

-- Cross-checking actors with high performance index based on
-- number of distinct films and average order of appearance in films
SELECT 
    ak.name,
    SUM(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE 0 END) AS total_order,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    MAX(c.nr_order) AS max_order
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
WHERE 
    ak.id IN (SELECT DISTINCT person_id FROM cast_info WHERE movie_id IN 
               (SELECT DISTINCT id FROM aka_title WHERE production_year >= 2000))
GROUP BY 
    ak.name
HAVING 
    total_movies > 5 AND max_order IS NOT NULL
ORDER BY 
    total_order DESC
LIMIT 10;
