WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt 
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt2.title,
        mt2.production_year,
        mt2.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN
        aka_title mt2 ON ml.linked_movie_id = mt2.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    AVG(mi.rating) AS average_rating,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    CASE 
        WHEN COUNT(DISTINCT ci.person_id) > 5 THEN 'Highly Casted'
        WHEN COUNT(DISTINCT ci.person_id) BETWEEN 3 AND 5 THEN 'Moderately Casted'
        ELSE 'Low Casted'
    END AS cast_category
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) IS NOT NULL AND AVG(mi.rating) IS NOT NULL
ORDER BY 
    average_rating DESC,
    mh.production_year ASC
LIMIT 100;
