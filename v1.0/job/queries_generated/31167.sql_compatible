
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        NULL AS parent_movie_id
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000  

    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.movie_id
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ah.name AS actor_name,
    mh.title AS movie_title,
    mh.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT cm.company_id) AS company_count,
    ROW_NUMBER() OVER (PARTITION BY ah.name ORDER BY COUNT(cm.company_id) DESC) AS actor_rank
FROM 
    MovieHierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    aka_name ah ON cc.subject_id = ah.person_id
LEFT JOIN 
    movie_companies cm ON mh.movie_id = cm.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    ah.name IS NOT NULL
    AND (mh.production_year IS NOT NULL AND mh.production_year < 2023) 
GROUP BY 
    ah.name, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT k.id) > 2  
ORDER BY 
    actor_rank, movie_title;
