WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind='movie') -- Base case for recursion

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5  -- Limit recursion depth to avoid excessive chaining
)
SELECT 
    mk.keyword,
    COALESCE(aka.name, 'Unknown') AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_role_order,
    STRING_AGG(DISTINCT mt.title, ', ') AS movie_titles,
    COUNT(DISTINCT mp.id) AS company_count,
    SUM(CASE WHEN mp.country_code IS NULL THEN 1 ELSE 0 END) AS missing_country_codes
FROM 
    movie_keyword mk
JOIN 
    aka_title mt ON mk.movie_id = mt.id
LEFT JOIN 
    cast_info ci ON mt.id = ci.movie_id
LEFT JOIN 
    aka_name aka ON ci.person_id = aka.person_id
LEFT JOIN 
    movie_companies mc ON mt.id = mc.movie_id
LEFT JOIN 
    company_name mp ON mc.company_id = mp.id
LEFT JOIN 
    movie_hierarchy mh ON mt.id = mh.movie_id
WHERE 
    mk.keyword IS NOT NULL 
    AND mt.production_year BETWEEN 2000 AND 2023
GROUP BY 
    mk.keyword, aka.name
ORDER BY 
    total_movies DESC, actor_name ASC;
