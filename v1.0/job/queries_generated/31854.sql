WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON mc.movie_id = t.movie_id
    JOIN 
        company_name cn ON cn.id = mc.company_id
    WHERE 
        cn.country_code = 'USA'

    UNION ALL

    SELECT 
        mh.movie_id,
        CONCAT(mh.title, ' (Part ', mh.level + 1, ')') AS title,
        mh.production_year,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title at ON at.id = ml.linked_movie_id
)
SELECT 
    mn.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS number_of_movies,
    AVG(mh.production_year) AS average_production_year,
    STRING_AGG(DISTINCT mh.title, ', ') AS movie_titles
FROM 
    movie_hierarchy mh
JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
JOIN 
    aka_name mn ON mn.id = ci.person_id
WHERE 
    mh.level < 3 -- Limiting levels for performance benchmarking
GROUP BY 
    mn.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 1 -- Only actors with more than one movie
ORDER BY 
    number_of_movies DESC
LIMIT 10;

-- Additional benchmarking for NULL logic
WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(m.production_year, 0) AS production_year,
        mu.name AS director_name
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON mi.movie_id = m.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Director')
    LEFT JOIN 
        company_name mu ON mu.imdb_id = mi.info
)
SELECT 
    COUNT(*) AS total_movies,
    COUNT(CASE WHEN director_name IS NULL THEN 1 END) AS movies_without_director,
    AVG(production_year) AS average_year
FROM 
    movie_details;
