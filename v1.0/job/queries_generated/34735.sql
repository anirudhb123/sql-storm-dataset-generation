WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    COUNT(DISTINCT c.person_id) AS total_cast,
    STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
    CASE 
        WHEN mh.level > 1 THEN 'Sequels/Related'
        ELSE 'Standalone Movie'
    END AS movie_type
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
WHERE 
    mh.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%')
    AND (mh.production_year IS NOT NULL AND mh.production_year > 1999)
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level
ORDER BY 
    mh.production_year DESC, mh.level ASC;
