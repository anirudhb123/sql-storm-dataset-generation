
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year = 2023

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mk.title,
        mk.production_year,
        mk.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mk ON ml.linked_movie_id = mk.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    kt.kind AS movie_kind,
    COALESCE(listagg(DISTINCT kn.keyword, ', '), 'No Keywords') AS keywords,
    COUNT(DISTINCT ci.person_id) AS num_cast,
    AVG(COALESCE(ci.nr_order, 0)) AS average_order,
    COUNT(DISTINCT i.person_id) AS num_info
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kn ON mk.keyword_id = kn.id
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    kind_type kt ON mh.kind_id = kt.id
LEFT JOIN 
    person_info i ON ci.person_id = i.person_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, kt.kind
HAVING 
    COUNT(DISTINCT ci.person_id) > 0 
ORDER BY 
    average_order DESC, mh.production_year DESC;
