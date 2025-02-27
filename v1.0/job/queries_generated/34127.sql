WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m2 ON ml.linked_movie_id = m2.id
    JOIN 
        MovieHierarchy mh ON m.id = mh.movie_id
    WHERE 
        m2.production_year >= 2000
)

SELECT 
    mk.keyword AS movie_keyword,
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT co.name) AS company_count,
    STRING_AGG(DISTINCT a.name, ', ') AS actors_list,
    AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE 0 END) AS avg_order,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS row_num
FROM 
    MovieHierarchy m
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = m.movie_id
LEFT JOIN 
    company_name co ON co.id = mc.company_id
LEFT JOIN 
    cast_info c ON c.movie_id = m.movie_id
LEFT JOIN 
    aka_name a ON a.person_id = c.person_id
WHERE 
    m.production_year IS NOT NULL
    AND mk.keyword IS NOT NULL
GROUP BY 
    mk.keyword, m.title, m.production_year
HAVING 
    COUNT(DISTINCT co.id) > 1
ORDER BY 
    m.production_year DESC, movie_keyword;
