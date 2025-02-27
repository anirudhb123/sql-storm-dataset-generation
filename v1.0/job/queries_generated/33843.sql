WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level,
        mt.id AS root_movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1,
        mh.root_movie_id
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 3
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    SUM(CASE 
        WHEN pm.gender = 'F' THEN 1 
        ELSE 0 
    END) AS female_cast,
    AVG(CASE 
        WHEN ay.info ILIKE '%Award%' THEN 1 
        ELSE 0 
    END) AS award_winning_percentage
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    name nm ON ak.person_id = nm.imdb_id
LEFT JOIN 
    person_info pm ON ci.person_id = pm.person_id AND pm.info_type_id = (SELECT id FROM info_type WHERE info = 'gender')
LEFT JOIN 
    movie_info ay ON mh.movie_id = ay.movie_id AND ay.info_type_id = (SELECT id FROM info_type WHERE info = 'awards')
WHERE 
    mh.level IS NOT NULL
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level
ORDER BY 
    mh.production_year DESC, mh.level ASC;
