
WITH RECURSIVE MovieHierarchy AS (
    
    SELECT
        m.movie_id,
        m.id AS movie_entry_id,
        m.title,
        1 AS level
    FROM 
        aka_title m
    WHERE
        m.production_year >= 2000  

    UNION ALL

    SELECT
        mh.movie_id,
        m.id AS movie_entry_id,
        m.title,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE
        mh.level < 5  
)

SELECT 
    COALESCE(aka.name, 'Unknown Actor') AS actor_name,
    title.title AS movie_title,
    title.production_year,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
    RANK() OVER (PARTITION BY title.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS production_rank
FROM 
    MovieHierarchy mh
JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id 
JOIN 
    aka_name aka ON ci.person_id = aka.person_id 
JOIN 
    aka_title title ON mh.movie_id = title.id 
LEFT JOIN 
    movie_companies mc ON title.id = mc.movie_id 
LEFT JOIN 
    movie_keyword mk ON title.id = mk.movie_id 
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id 
WHERE 
    title.production_year IS NOT NULL 
    AND title.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
GROUP BY 
    actor_name, title.title, title.production_year 
HAVING 
    COUNT(DISTINCT mc.company_id) > 1  
ORDER BY 
    title.production_year DESC, 
    production_rank;
