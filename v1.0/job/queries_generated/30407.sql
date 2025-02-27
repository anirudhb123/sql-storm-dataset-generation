WITH RECURSIVE MovieHierarchy AS (
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
        ml.linked_movie_id AS movie_id,
        a.title,
        a.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT DISTINCT mc.company_id) AS number_of_companies,
    AVG(m.keyword_count) AS avg_keywords_per_movie,
    SUM(CASE WHEN r.role = 'lead' THEN 1 ELSE 0 END) AS leads_count
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.id
JOIN 
    aka_title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
) m ON t.id = m.movie_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    MovieHierarchy mh ON t.id = mh.movie_id
WHERE 
    t.production_year >= 2000
    AND a.name IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    number_of_companies DESC, avg_keywords_per_movie DESC;
