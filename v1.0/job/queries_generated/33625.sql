WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        c.movie_id,
        1 AS depth
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
    
    UNION ALL
    
    SELECT 
        c.person_id,
        a.name,
        c.movie_id,
        ah.depth + 1
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        actor_hierarchy ah ON c.movie_id = ah.movie_id
    WHERE 
        a.name IS NOT NULL AND ah.depth < 2
)

SELECT 
    at.title,
    COUNT(DISTINCT ch.person_id) AS num_actors,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    ARRAY_AGG(DISTINCT co.name) AS production_companies,
    mn.keyword AS relevant_keyword,
    CASE 
        WHEN COUNT(DISTINCT ch.person_id) > 10 THEN 'Large Cast'
        WHEN COUNT(DISTINCT ch.person_id) BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT ch.person_id) DESC) AS rank_by_cast_size
FROM 
    aka_title at
LEFT JOIN 
    complete_cast cc ON at.id = cc.movie_id
LEFT JOIN 
    cast_info ch ON cc.id = ch.movie_id
LEFT JOIN 
    aka_name ak ON ch.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = cc.movie_id
LEFT JOIN 
    company_name co ON co.id = mc.company_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = cc.movie_id
LEFT JOIN 
    keyword mn ON mn.id = mk.keyword_id
WHERE 
    at.production_year >= 2000
    AND (mn.keyword IS NULL OR mn.keyword LIKE '%action%') -- handling NULL logic in keywords
    AND co.country_code IS NOT NULL
GROUP BY 
    at.title, mn.keyword
ORDER BY 
    num_actors DESC, at.title
LIMIT 50;
