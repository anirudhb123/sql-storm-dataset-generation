WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000 -- filter for movies after 2000
    UNION ALL
    SELECT 
        m.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link m
    JOIN 
        aka_title mt ON mt.id = m.linked_movie_id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = m.movie_id
)
SELECT 
    kh.keyword,
    COUNT(DISTINCT mc.movie_id) AS movie_count,
    AVG(CASE WHEN ai.company_id IS NULL THEN 0 ELSE 1 END) AS has_company,
    STRING_AGG(DISTINCT at.title, ', ') AS related_movies,
    MIN(at.production_year) AS earliest_movie,
    MAX(at.production_year) AS latest_movie
FROM 
    movie_keyword mk
JOIN 
    keyword kh ON mk.keyword_id = kh.id
LEFT JOIN 
    movie_companies mc ON mk.movie_id = mc.movie_id
LEFT JOIN 
    company_name ai ON mc.company_id = ai.id AND ai.country_code IS NOT NULL
JOIN 
    movie_hierarchy at ON mk.movie_id = at.movie_id
WHERE 
    kh.keyword IS NOT NULL
GROUP BY 
    kh.keyword
HAVING 
    COUNT(DISTINCT mc.movie_id) > 0 
ORDER BY 
    movie_count DESC
LIMIT 10;
