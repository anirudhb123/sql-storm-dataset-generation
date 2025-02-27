WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.depth + 1
    FROM 
        movie_link ml
    INNER JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    INNER JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.depth,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    COUNT(DISTINCT mc.company_id) AS company_count,
    AVG(pi.info::FLOAT) FILTER (WHERE pi.info IS NOT NULL) AS avg_person_info,
    COUNT(DISTINCT kw.keyword) AS keyword_count,
    CASE 
        WHEN mh.production_year < 2010 THEN 'Pre-2010'
        WHEN mh.production_year >= 2010 AND mh.production_year < 2020 THEN '2010-2019'
        ELSE 'Post-2019'
    END AS production_period
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_info pi ON mh.movie_id = pi.movie_id AND pi.info_type_id = 1 -- Assume 1 is for relevant personal info
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.depth
HAVING 
    COUNT(DISTINCT ak.name) > 2
ORDER BY 
    mh.production_year DESC, mh.depth ASC;
