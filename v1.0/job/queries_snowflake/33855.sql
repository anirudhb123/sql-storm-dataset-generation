
WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND mt.production_year >= 2000
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.id
)
SELECT
    ak.name AS actor_name,
    at.title AS movie_title,
    mh.level AS movie_level,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies,
    SUM(CASE 
            WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget') 
            THEN COALESCE(CAST(mi.info AS INTEGER), 0) 
            ELSE 0 
        END) AS total_budget,
    LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
FROM
    MovieHierarchy mh
JOIN
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN
    cast_info ci ON ci.id = cc.subject_id
JOIN
    aka_name ak ON ak.person_id = ci.person_id
JOIN
    aka_title at ON at.id = mh.movie_id
LEFT JOIN
    movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN
    company_name cn ON cn.id = mc.company_id
LEFT JOIN
    movie_info mi ON mi.movie_id = mh.movie_id
LEFT JOIN
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN
    keyword k ON k.id = mk.keyword_id
GROUP BY
    ak.name, at.title, mh.level
HAVING
    COUNT(DISTINCT mc.company_id) > 0
ORDER BY
    mh.level, ak.name, at.title;
