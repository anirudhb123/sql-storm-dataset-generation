WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    AVG(pi.info::numeric) AS avg_rating,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY m.production_year DESC) AS actor_movie_rank
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title m ON c.movie_id = m.id
LEFT JOIN 
    movie_companies mc ON m.id = mc.movie_id
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_hierarchy mh ON m.id = mh.movie_id
WHERE 
    m.production_year > 2000 
    AND (c.note IS NULL OR c.note != 'uncredited')
GROUP BY 
    a.name, m.title, m.production_year
HAVING 
    AVG(pi.info::numeric) > 7.0
ORDER BY 
    m.production_year DESC, actor_name;
This SQL query utilizes several advanced SQL concepts such as Common Table Expressions (CTEs) for creating a movie hierarchy, joining multiple tables with various types of joins, aggregation functions, window functions, and a condition for filtering out uncredited actors. It also performs a subquery in the HAVING clause to enclose a more complex rating filter. The query demonstrates a comprehensive analysis of actor performance in years post-2000, factoring in their collaboration with multiple companies and categorized by keywords.
