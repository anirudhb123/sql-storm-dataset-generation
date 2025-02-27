WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        CAST(1 AS integer) AS level
    FROM aka_title mt
    WHERE mt.production_year >= 2000  -- Start with movies from the year 2000 onward

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM movie_link ml
    JOIN aka_title at ON ml.linked_movie_id = at.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
    SUM(CASE WHEN ak.gender = 'F' THEN 1 ELSE 0 END) AS female_cast_count,
    AVG(pi.info_type_id) AS average_info_type_id,
    MAX(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info='Box Office') 
             THEN mi.info::numeric ELSE NULL END) AS box_office
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id
WHERE 
    mh.level <= 2  -- Limit the hierarchy to 2 levels
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 0  -- Only include movies that have cast members
ORDER BY 
    mh.production_year DESC, total_cast DESC;
