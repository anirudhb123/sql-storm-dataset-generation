WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth,
        mt.id AS root_id
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1,
        mh.root_id
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.depth,
    COALESCE(c.name, 'Unknown') AS company_name,
    COUNT(DISTINCT ca.person_id) AS actor_count,
    STRING_AGG(DISTINCT p.name, ', ') AS actors,
    AVG(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating') THEN CAST(mi.info AS DECIMAL) ELSE NULL END) AS average_rating
FROM 
    MovieHierarchy m
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ca ON cc.subject_id = ca.person_id
LEFT JOIN 
    aka_name p ON ca.person_id = p.person_id
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id
GROUP BY 
    m.movie_id, m.title, m.production_year, m.depth, c.name
HAVING 
    COUNT(DISTINCT ca.person_id) > 0
ORDER BY 
    average_rating DESC NULLS LAST, m.production_year DESC, m.depth ASC
LIMIT 100;
