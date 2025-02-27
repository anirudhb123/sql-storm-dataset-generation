WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

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
    mn.name AS actor_name,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT ci.id) AS total_cast,
    AVG(pi.info) FILTER (WHERE pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Age')) AS avg_age,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY COUNT(DISTINCT ci.id) DESC) AS cast_rank,
    CASE 
        WHEN ci.nr_order IS NULL THEN 'Unknown Role'
        ELSE rt.role 
    END AS role_name
FROM 
    movie_hierarchy mh
JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
JOIN 
    aka_name mn ON ci.person_id = mn.person_id
LEFT JOIN 
    person_info pi ON mn.person_id = pi.person_id
LEFT JOIN 
    role_type rt ON ci.role_id = rt.id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
GROUP BY 
    mn.name, mh.movie_id, mh.title, mh.production_year, ci.nr_order, rt.role
HAVING 
    COUNT(DISTINCT ci.id) > 5
ORDER BY 
    mh.production_year DESC, total_cast DESC;
