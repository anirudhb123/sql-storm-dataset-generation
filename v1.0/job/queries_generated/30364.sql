WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        sub_mt.title,
        sub_mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title sub_mt ON ml.movie_id = sub_mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.title,
    mh.production_year,
    COUNT(cast.id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
    CASE 
        WHEN mh.production_year < 2010 THEN 'Older'
        ELSE 'Newer'
    END AS age_category,
    AVG(CAST(CASE WHEN pi.info IS NULL THEN 0 ELSE 1 END AS FLOAT)) AS info_presence_rate,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(cast.id) DESC) AS rank_by_cast_size
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info cast ON cc.subject_id = cast.person_id
LEFT JOIN 
    aka_name ak ON cast.person_id = ak.person_id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Birth Date' LIMIT 1)
WHERE 
    mh.level = 1
GROUP BY 
    mh.title, mh.production_year
HAVING 
    AVG(CAST(CASE WHEN pi.info IS NULL THEN 0 ELSE 1 END AS FLOAT)) < 0.75
ORDER BY 
    mh.production_year DESC, total_cast DESC;
