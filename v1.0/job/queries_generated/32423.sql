WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        0 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000  -- Starting from the year 2000 for recent movies

    UNION ALL

    SELECT 
        ml.linked_movie_id, 
        a.title, 
        mh.depth + 1
    FROM 
        movie_link ml 
        JOIN aka_title a ON ml.linked_movie_id = a.movie_id
        JOIN movie_hierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    m.id AS movie_id,
    m.title AS movie_title,
    m.production_year AS year,
    COALESCE(ka.names, 'No Cast') AS cast_names,
    COALESCE(kw.keywords, 'No Keywords') AS keywords,
    AVG(pi.info) AS avg_person_info
FROM 
    aka_title m
LEFT JOIN 
    (SELECT 
         c.movie_id,
         STRING_AGG(DISTINCT an.name, ', ' ORDER BY an.name) AS names
     FROM 
         cast_info c 
         JOIN aka_name an ON c.person_id = an.person_id
     GROUP BY 
         c.movie_id) ka ON m.id = ka.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = m.id
LEFT JOIN 
    person_info pi ON mc.company_id = pi.person_id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
GROUP BY 
    m.id, m.title, m.production_year, ka.names, kw.keywords
HAVING 
    COUNT(DISTINCT pi.info) > 0  -- Only include movies that have person info
ORDER BY 
    year DESC, 
    movie_title
LIMIT 50;

This query utilizes various SQL constructs including:
- A recursive CTE (`movie_hierarchy`) to explore linked movies and their relationships.
- Outer joins to gather cast names and keywords, ensuring that movies without these relationships are still displayed.
- A correlated subquery to aggregate cast names.
- Various calculations with the use of `COALESCE` to handle NULL values.
- A `HAVING` clause with a condition on counted entries, filtering out movies without relevant information. 
- The final result is sorted by year and title, restricting to the latest relevant films.
