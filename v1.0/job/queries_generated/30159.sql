WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        t.imdb_index,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year BETWEEN 2000 AND 2023

    UNION ALL

    SELECT 
        t.id AS movie_id,
        linked.title,
        linked.production_year,
        linked.kind_id,
        linked.imdb_index,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title linked ON ml.linked_movie_id = linked.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.title,
    mh.production_year,
    COUNT(DISTINCT cc.person_id) AS num_cast,
    AVG(DISTINCT pi.info_type_id) AS avg_info_type_id,
    STRING_AGG(DISTINCT ckt.kind, ', ') AS company_types,
    SUM(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT cc.person_id) DESC) AS rank
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_type ckt ON mc.company_type_id = ckt.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    person_info pi ON cc.person_id = pi.person_id
LEFT JOIN 
    cast_info ci ON cc.id = ci.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT cc.person_id) > 2
    AND AVG(DISTINCT pi.info_type_id) IS NOT NULL
ORDER BY 
    mh.production_year DESC, num_cast DESC;
