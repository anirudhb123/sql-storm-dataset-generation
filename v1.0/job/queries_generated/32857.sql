WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh 
    ON 
        ml.movie_id = mh.movie_id
    JOIN 
        aka_title m 
    ON 
        m.id = ml.linked_movie_id
)
SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    SUM(CASE 
        WHEN mk.keyword IS NOT NULL THEN 1 
        ELSE 0 
    END) AS movies_with_keywords,
    MAX(mh.production_year) AS latest_movie_year,
    MIN(mh.production_year) AS earliest_movie_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords_list,
    AVG(m.production_year) OVER (PARTITION BY a.id) AS avg_production_year
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    movie_keyword k ON mk.keyword_id = k.id
OUTER APPLY (
    SELECT 
        mh.title, mh.production_year
    FROM 
        MovieHierarchy mh 
    WHERE 
        mh.movie_id = c.movie_id
) mh
WHERE 
    a.name IS NOT NULL 
    AND t.production_year IS NOT NULL 
    AND t.production_year BETWEEN 2000 AND 2023 
    AND (a.name LIKE '%Smith%' OR a.name LIKE '%Johnson%')
GROUP BY 
    a.id
HAVING 
    COUNT(DISTINCT c.movie_id) > 5
ORDER BY 
    total_movies DESC, latest_movie_year DESC;

