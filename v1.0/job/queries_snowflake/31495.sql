
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS depth
    FROM 
        aka_title m
    WHERE 
        m.kind_id = 1  

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1 AS depth
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.movie_id
    JOIN 
        movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
)

SELECT 
    mh.title AS main_movie_title,
    mh.production_year AS main_movie_year,
    person.name AS actor_name,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    AVG(COALESCE(c.nr_order, 0)) AS avg_role_order,
    COUNT(DISTINCT m2.title) AS older_movies_count
FROM 
    movie_hierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.person_id
JOIN 
    aka_name person ON c.person_id = person.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    aka_title m2 ON c.movie_id = m2.id
WHERE 
    mh.depth < 3
GROUP BY 
    mh.movie_id, person.name, mh.title, mh.production_year
ORDER BY 
    main_movie_year DESC, actor_name;
