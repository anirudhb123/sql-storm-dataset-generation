WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
)
SELECT 
    pa.name AS actor_name,
    at.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT ki.keyword) AS keywords_count,
    STRING_AGG(DISTINCT co.name, ', ') AS company_names,
    ROW_NUMBER() OVER (PARTITION BY pa.name ORDER BY mh.production_year DESC) AS rn,
    MAX(CASE WHEN pi.info_type_id = 1 THEN pi.info END) AS birth_info,
    MAX(CASE WHEN pi.info_type_id = 2 THEN pi.info END) AS death_info
FROM 
    cast_info AS ci
JOIN 
    aka_name AS pa ON ci.person_id = pa.person_id
JOIN 
    aka_title AS at ON ci.movie_id = at.id
LEFT JOIN 
    movie_keyword AS mk ON mk.movie_id = at.id
LEFT JOIN 
    keyword AS ki ON mk.keyword_id = ki.id
LEFT JOIN 
    movie_companies AS mc ON mc.movie_id = at.id
LEFT JOIN 
    company_name AS co ON mc.company_id = co.id
LEFT JOIN 
    person_info AS pi ON ci.person_id = pi.person_id
JOIN 
    movie_hierarchy AS mh ON mh.movie_id = at.id
WHERE 
    mh.level <= 3
GROUP BY 
    pa.name, at.title, mh.production_year
HAVING 
    COUNT(DISTINCT mk.keyword_id) > 5 OR COUNT(DISTINCT co.name) > 3
ORDER BY 
    mh.production_year DESC, actor_name ASC;
