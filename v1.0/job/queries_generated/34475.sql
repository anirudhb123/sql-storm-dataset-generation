WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE
        mt.production_year >= 2000

    UNION ALL

    SELECT
        ml.linked_movie_id,
        m2.title,
        m2.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m2 ON ml.movie_id = m2.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    ak.md5sum AS actor_md5sum,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT mc.company_id) AS num_production_companies,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY COUNT(mc.company_id) DESC) AS production_company_rank,
    MAX(mvi.info) AS best_review
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_info mvi ON mh.movie_id = mvi.movie_id AND mvi.info_type_id = (SELECT id FROM info_type WHERE info = 'Review')
GROUP BY 
    ak.name, ak.md5sum, mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    mh.production_year DESC, production_company_rank;
