WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year < 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        at.production_year < 2000
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.depth,
    COALESCE(CAST(COUNT(DISTINCT ci.person_id) AS INTEGER), 0) AS total_cast,
    string_agg(DISTINCT an.name, ', ') AS actor_names,
    AVG(COALESCE(CAST(mi.info AS INTEGER), 0)) AS average_rating
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
WHERE 
    mh.depth <= 3
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.depth
ORDER BY 
    average_rating DESC NULLS LAST, 
    mh.production_year DESC, 
    mh.title;
