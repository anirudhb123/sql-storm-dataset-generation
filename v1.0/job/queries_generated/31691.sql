WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
      
    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        aka_title m ON mh.movie_id = m.episode_of_id
    WHERE 
        m.episode_of_id IS NOT NULL
)

SELECT 
    ak.name AS actor_name,
    COUNT(ci.movie_id) AS total_movies,
    AVG(CASE 
            WHEN m.production_year IS NOT NULL THEN m.production_year 
            ELSE NULL 
        END) AS avg_movie_year,
    STRING_AGG(DISTINCT mt.title, ', ') AS movie_titles,
    ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY COUNT(ci.movie_id) DESC) AS actor_rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    MovieHierarchy m ON ci.movie_id = m.movie_id
LEFT JOIN 
    aka_title mt ON m.movie_id = mt.id AND mt.production_year BETWEEN 2000 AND 2020
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.id, ak.name
HAVING 
    COUNT(ci.movie_id) > 5
ORDER BY 
    total_movies DESC, actor_name;

-- Get the count of titles per company and the total budget, including NULLs
SELECT 
    cn.name AS company_name,
    COUNT(DISTINCT mt.id) AS total_titles,
    SUM(COALESCE(mi.info::numeric, 0)) AS total_budget
FROM 
    company_name cn
JOIN 
    movie_companies mc ON cn.id = mc.company_id
JOIN 
    aka_title mt ON mc.movie_id = mt.id
LEFT JOIN 
    movie_info mi ON mt.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')
WHERE 
    cn.country_code IS NOT NULL
GROUP BY 
    cn.id, cn.name
HAVING 
    COUNT(DISTINCT mt.id) > 10
ORDER BY 
    total_budget DESC;

-- Fetch actors with roles, excluding any who were in fewer than 3 movies, sorted by their last movie
SELECT 
    ak.name AS actor_name,
    MAX(mt.production_year) AS last_movie_year,
    COUNT(DISTINCT ci.movie_id) AS movie_count,
    STRING_AGG(DISTINCT mt.title, ', ') AS titles
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title mt ON ci.movie_id = mt.id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.id, ak.name
HAVING 
    COUNT(DISTINCT ci.movie_id) >= 3
ORDER BY 
    last_movie_year DESC;
