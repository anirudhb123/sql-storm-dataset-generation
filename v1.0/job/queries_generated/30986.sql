WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title mt
    JOIN 
        title t ON mt.movie_id = t.id
    WHERE 
        t.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        linked.title,
        linked.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        title linked ON ml.linked_movie_id = linked.id
    WHERE 
        linked.production_year >= 2000
)
SELECT 
    mh.title,
    mh.production_year,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    STRING_AGG(DISTINCT an.name, ', ') AS actor_names,
    AVG( pi.info IS NOT NULL)::int AS has_person_info,
    CASE 
        WHEN mh.level = 1 THEN 'Top Level'
        WHEN mh.level = 2 THEN 'Second Level'
        ELSE 'Lower Level'
    END AS hierarchy_level
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
LEFT JOIN 
    person_info pi ON ci.person_id = pi.person_id AND pi.info_type_id = 1
WHERE 
    mh.production_year BETWEEN 2000 AND 2020
GROUP BY 
    mh.title, mh.production_year, mh.level
HAVING 
    COUNT(DISTINCT ci.person_id) > 2
ORDER BY 
    mh.production_year DESC, total_cast DESC;

