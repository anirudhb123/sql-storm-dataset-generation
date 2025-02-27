WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        CAST(NULL AS text) AS parent_movie,
        0 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
        
    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.title AS parent_movie,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy AS mh ON mh.movie_id = ml.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.parent_movie,
    mh.level,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
    ARRAY_AGG(DISTINCT COALESCE(ci.note, 'No Note')) AS cast_notes
FROM 
    MovieHierarchy AS mh
LEFT JOIN 
    complete_cast AS cc ON cc.movie_id = mh.movie_id
LEFT JOIN 
    cast_info AS ci ON ci.movie_id = cc.movie_id
LEFT JOIN 
    aka_name AS ak ON ak.person_id = ci.person_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.parent_movie, mh.level
ORDER BY 
    mh.level DESC, mh.production_year DESC
LIMIT 100;
This SQL query combines a recursive Common Table Expression (CTE) to fetch movie hierarchies by joining linked movies. It incorporates outer joins, aggregation functions such as `COUNT` and `STRING_AGG`, and `ARRAY_AGG` for collecting cast details per movie along with their notes. The results are grouped by various attributes, ordered by depth in the hierarchy and production year, with a limit on returned rows.
