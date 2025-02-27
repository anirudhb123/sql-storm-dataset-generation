WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id, 
           mt.title,
           mt.production_year,
           mcl.linked_movie_id,
           1 AS hierarchy_level
    FROM aka_title mt
    LEFT JOIN movie_link mcl ON mt.id = mcl.movie_id
    WHERE mt.production_year IS NOT NULL AND mt.production_year < 2000

    UNION ALL

    SELECT mt.id AS movie_id, 
           mt.title,
           mt.production_year,
           mcl.linked_movie_id,
           mh.hierarchy_level + 1
    FROM aka_title mt
    INNER JOIN movie_link mcl ON mt.id = mcl.movie_id
    INNER JOIN MovieHierarchy mh ON mcl.linked_movie_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(mt.linked_movie_id, 'No Links') AS linked_movie,
    mh.hierarchy_level,
    COUNT(DISTINCT c.person_id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    MAX(CASE WHEN ak.name IS NULL THEN 'Unknown Actor' ELSE ak.name END) AS last_actor,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.hierarchy_level, mh.title) AS rank,
    CASE 
        WHEN COUNT(DISTINCT c.person_id) > 5 THEN 'Large Cast'
        WHEN COUNT(DISTINCT c.person_id) BETWEEN 2 AND 5 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM MovieHierarchy mh
LEFT JOIN complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN cast_info c ON cc.subject_id = c.id
LEFT JOIN aka_name ak ON c.person_id = ak.person_id
LEFT JOIN aka_title aTitle ON mh.movie_id = aTitle.id
LEFT JOIN movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN movie_keyword mk ON mh.movie_id = mk.movie_id
WHERE mi.note IS NULL OR mk.keyword_id IS NOT NULL
GROUP BY mh.movie_id, mh.title, mh.production_year, mh.linked_movie_id, mh.hierarchy_level
HAVING COUNT(DISTINCT c.person_id) IS NOT NULL OR MAX(ak.name) IS NOT NULL
ORDER BY mh.production_year DESC, rank
LIMIT 100 OFFSET 10;
