WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        mt.production_year, 
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id, 
        a.title AS movie_title, 
        a.production_year, 
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ah.name AS actor_name,
    mh.movie_title,
    mh.production_year,
    COUNT(DISTINCT mc.company_id) AS company_count,
    SUM(CASE WHEN aws.note IS NOT NULL THEN 1 ELSE 0 END) AS notable_roles,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    RANK() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank_by_company_count
FROM 
    MovieHierarchy mh
JOIN 
    complete_cast cc ON cc.movie_id = mh.movie_id
JOIN 
    aka_name ah ON cc.subject_id = ah.person_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    (SELECT 
        person_id, 
        note
    FROM 
        cast_info 
    WHERE 
        person_role_id IS NOT NULL) aws ON aws.person_id = ah.person_id
GROUP BY 
    ah.name, mh.movie_title, mh.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 0 
ORDER BY 
    mh.production_year DESC, rank_by_company_count
LIMIT 100;