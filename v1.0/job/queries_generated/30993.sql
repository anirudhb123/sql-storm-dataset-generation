WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 

    UNION ALL 

    SELECT 
        ml.linked_movie_id,
        a.title,
        a.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    SUM(CASE WHEN CAST(c.person_id AS TEXT) IS NULL THEN 1 ELSE 0 END) AS null_person_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
    AVG(mk.avg_key_count) AS avg_keyword_count 
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id 
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id 
LEFT JOIN 
    (SELECT 
         movie_id, COUNT(*) AS avg_key_count 
     FROM 
         movie_keyword 
     GROUP BY 
         movie_id
    ) mk ON mh.movie_id = mk.movie_id 
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id 
GROUP BY 
    mh.movie_id, mh.movie_title, mh.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 0 
ORDER BY 
    mh.production_year DESC, mh.movie_title;
