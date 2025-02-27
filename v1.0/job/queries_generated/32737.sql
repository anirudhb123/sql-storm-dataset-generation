WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        1 AS level,
        mt.production_year,
        NULL AS parent_id
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
        
    UNION ALL
    
    SELECT
        ml.linked_movie_id,
        at.title,
        mh.level + 1,
        at.production_year,
        mh.movie_id
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT
    mh.level,
    mh.title,
    mh.production_year,
    COUNT(DISTINCT cc.person_id) AS cast_count,
    STRING_AGG(DISTINCT an.name, ', ') AS actor_names,
    AVG(mi.info IS NOT NULL)::FLOAT AS avg_info_present,
    CASE 
        WHEN mh.production_year IS NULL THEN 'Unknown Year'
        ELSE CAST(mh.production_year AS text)
    END AS year_output,
    ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mh.production_year) AS row_num
FROM
    MovieHierarchy mh
LEFT JOIN
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN
    aka_name an ON cc.subject_id = an.person_id
LEFT JOIN
    movie_info mi ON mh.movie_id = mi.movie_id
WHERE
    mh.level <= 3
GROUP BY
    mh.level, mh.title, mh.production_year
ORDER BY
    mh.level, cast_count DESC, year_output;
