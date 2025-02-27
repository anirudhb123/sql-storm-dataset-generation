WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.id IS NOT NULL
    
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    co.name AS company_name,
    COUNT(DISTINCT mc.movie_id) AS total_movies,
    SUM(CASE WHEN k.keyword IS NOT NULL THEN 1 ELSE 0 END) AS movies_with_keywords,
    AVG(mh.level) AS avg_level_in_hierarchy
FROM 
    movie_companies mc
INNER JOIN 
    company_name co ON mc.company_id = co.id
INNER JOIN 
    movie_info mi ON mc.movie_id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON mc.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_hierarchy mh ON mc.movie_id = mh.movie_id
WHERE 
    co.country_code IS NOT NULL
    AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'genre') -- Correlated subquery for specific genre
    AND (mi.info IS NOT NULL OR mi.note IS NOT NULL) -- Checking for NULL logic
GROUP BY 
    co.name
HAVING 
    COUNT(DISTINCT mc.movie_id) > 50 -- Only include companies with more than 50 movies
ORDER BY 
    total_movies DESC
LIMIT 10;

WITH keyword_count AS (
    SELECT 
        movie_id, 
        COUNT(*) AS cnt_keywords
    FROM 
        movie_keyword
    GROUP BY 
        movie_id
)

SELECT 
    t.title,
    t.production_year,
    COALESCE(kc.cnt_keywords, 0) AS keyword_count,
    RANK() OVER (ORDER BY COALESCE(kc.cnt_keywords, 0) DESC) AS ranking
FROM
    aka_title t
LEFT JOIN 
    keyword_count kc ON t.id = kc.movie_id
WHERE 
    t.production_year = (SELECT MAX(production_year) FROM aka_title) -- Latest movies
    AND t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('Feature', 'Short')) -- Filtering kind
ORDER BY 
    ranking
LIMIT 5;
