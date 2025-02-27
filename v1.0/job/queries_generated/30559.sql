WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::integer AS parent_id,
        1 AS level
    FROM aka_title mt
    WHERE mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.movie_id,
        mh.level + 1
    FROM movie_link ml
    JOIN aka_title at ON ml.linked_movie_id = at.id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    COUNT(DISTINCT ci.person_id) AS num_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    SUM(CASE WHEN ik.info IS NOT NULL THEN 1 ELSE 0 END) AS info_count,
    MAX(mh.level) AS hierarchy_level
FROM 
    MovieHierarchy m
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id
LEFT JOIN 
    movie_info_idx ik ON m.movie_id = ik.movie_id
GROUP BY 
    m.movie_id, m.title, m.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 2
ORDER BY 
    m.production_year DESC, num_cast DESC;

-- This query performs an intricate selection of movies along with their associated actors,
-- information counts, and constructs a movie hierarchy through recursive common table expressions (CTEs).
