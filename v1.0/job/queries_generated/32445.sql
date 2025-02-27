WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        title.title,
        title.production_year,
        mh.level + 1,
        mh.movie_id
    FROM 
        movie_link ml
    JOIN 
        title ON ml.linked_movie_id = title.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    COUNT(DISTINCT cc.person_id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
    MAX(mk.keyword) FILTER (WHERE mk.keyword IS NOT NULL) AS primary_keyword,
    COALESCE(SUM(mci.note IS NOT NULL)::int, 0) AS notes_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    movie_info mci ON mh.movie_id = mci.movie_id AND mci.info_type_id = (SELECT id FROM info_type WHERE info = 'box office')
WHERE 
    mh.level <= 3
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level
ORDER BY 
    mh.production_year DESC, total_cast DESC;
