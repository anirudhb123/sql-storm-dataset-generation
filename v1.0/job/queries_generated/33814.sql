WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(DISTINCT pc.company_id) AS production_companies,
    AVG(mr.rating) AS average_rating,
    MAX(mr.box_office) AS max_box_office
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
LEFT JOIN 
    (SELECT 
        movie_id, 
        MAX(box_office) AS box_office,
        (SELECT 
            COUNT(*) 
         FROM 
            movie_keyword mk 
         WHERE 
            mk.movie_id = m.movie_id) AS keyword_count
     FROM 
        movie_info m
     WHERE 
        m.info_type_id = (SELECT id FROM info_type WHERE info = 'box office')
     GROUP BY 
        movie_id) AS mr ON mh.movie_id = mr.movie_id
GROUP BY 
    a.name, mt.title, mt.production_year
HAVING 
    COUNT(DISTINCT pc.company_id) > 1 AND AVG(mr.rating) IS NOT NULL
ORDER BY 
    average_rating DESC, production_year DESC;
