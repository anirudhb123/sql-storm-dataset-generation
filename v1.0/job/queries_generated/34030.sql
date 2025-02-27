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
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    ROW_NUMBER() OVER(PARTITION BY ak.id ORDER BY at.production_year DESC) AS rn,
    COALESCE(NULLIF(mci.note, ''), 'No Note') AS company_note
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON at.id = mi.movie_id AND mi.info_type_id = 1
RIGHT JOIN 
    movie_hierarchy mh ON at.id = mh.movie_id
GROUP BY 
    ak.name, at.title, at.production_year, mci.note
HAVING 
    COUNT(DISTINCT mk.keyword) > 3
ORDER BY 
    at.production_year DESC, ak.name;
