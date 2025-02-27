WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        CAST(mt.title AS VARCHAR) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1,
        CAST(mh.path || ' -> ' || at.title AS VARCHAR)
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        at.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
)

SELECT 
    mh.path,
    mh.title AS root_title,
    mh.production_year,
    COALESCE(ak.name, 'Unknown') AS actor_name,
    COUNT(DISTINCT cc.subject_id) AS num_cast_members,
    AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY mh.movie_id) AS has_notes_ratio
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    mh.production_year > 2000
GROUP BY 
    mh.movie_id, mh.path, mh.title, mh.production_year, ak.name
ORDER BY 
    mh.production_year DESC, num_cast_members DESC;
