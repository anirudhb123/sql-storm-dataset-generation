
WITH RECURSIVE MovieHierarchy AS (
    
    SELECT 
        ml.movie_id AS root_movie_id,
        ml.linked_movie_id,
        1 AS level
    FROM 
        movie_link ml
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel') 

    UNION ALL

    SELECT 
        mh.root_movie_id,
        ml.linked_movie_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel')
)

SELECT 
    m.title AS Movie_Title,
    COALESCE(a.name, 'Unknown') AS Actor_Name,
    COUNT(DISTINCT mh.linked_movie_id) AS Linked_Movies_Count,
    SUM(CASE WHEN mi.info IS NOT NULL THEN 1 ELSE 0 END) AS Info_Count,  
    AVG(CASE WHEN ci.nr_order IS NULL THEN 0 ELSE ci.nr_order END) AS Avg_Nr_Order,  
    LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS Keywords,  
    MAX(CASE WHEN ci.note IS NOT NULL THEN ci.note ELSE 'No Note' END) AS Last_Note
FROM 
    aka_title m
LEFT JOIN 
    cast_info ci ON m.id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    MovieHierarchy mh ON m.id = mh.root_movie_id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id 
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id 

WHERE 
    m.production_year >= EXTRACT(YEAR FROM DATE '2024-10-01') - 10
GROUP BY 
    m.title, a.name
ORDER BY 
    Linked_Movies_Count DESC, Avg_Nr_Order ASC
LIMIT 50;
