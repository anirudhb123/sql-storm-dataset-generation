
WITH MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM title m
    WHERE m.kind_id = 1  

    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM movie_link ml
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN title t ON ml.linked_movie_id = t.id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(DISTINCT ca.person_id) AS num_actors,
    LISTAGG(DISTINCT ak.name, '; ') WITHIN GROUP (ORDER BY ak.name) AS actor_names,
    AVG(mo.info_length) AS avg_info_length
FROM MovieHierarchy mh
LEFT JOIN complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN cast_info ca ON cc.subject_id = ca.person_id
LEFT JOIN (
    SELECT 
        mi.movie_id,
        AVG(LENGTH(mi.info)) AS info_length
    FROM movie_info mi
    GROUP BY mi.movie_id
) mo ON mh.movie_id = mo.movie_id
LEFT JOIN aka_name ak ON ak.person_id = ca.person_id
WHERE mh.production_year >= 2000
GROUP BY mh.movie_id, mh.title, mh.production_year
ORDER BY mh.production_year DESC, num_actors DESC
LIMIT 50;
