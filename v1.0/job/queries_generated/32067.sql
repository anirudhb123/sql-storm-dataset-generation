WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt 
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1 AS depth
    FROM 
        movie_link ml 
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.depth,
    COUNT(DISTINCT ci.person_id) AS total_cast_members,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count,
    MAX(pc.name) AS most_frequent_company,
    AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE NULL END) AS avg_order_position,
    STRING_AGG(DISTINCT CONCAT(ak.name, '(', ak.id, ')'), ', ') AS actor_names
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name pc ON mc.company_id = pc.id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id 
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.depth
HAVING 
    COUNT(DISTINCT ci.person_id) > 5 AND 
    AVG(COALESCE(ci.nr_order, 0)) < 50
ORDER BY 
    mh.production_year DESC, total_cast_members DESC;
