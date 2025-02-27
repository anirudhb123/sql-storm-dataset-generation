WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    mh.title,
    mh.production_year,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
    COUNT(cc.id) AS total_cast,
    AVG(CASE WHEN p.gender IS NULL THEN 0 ELSE 1 END) AS male_ratio,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY total_cast DESC) AS rank
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    aka_name an ON cc.person_id = an.person_id
LEFT JOIN 
    name p ON an.id = p.id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
GROUP BY 
    mh.title, mh.production_year
HAVING 
    COUNT(cc.id) > 3
ORDER BY 
    mh.production_year DESC, total_cast DESC;
