WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mv.linked_movie_id,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link mv ON mt.id = mv.movie_id
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mv.linked_movie_id,
        mh.level + 1
    FROM 
        aka_title mt
    JOIN 
        movie_link mv ON mt.id = mv.movie_id
    JOIN 
        movie_hierarchy mh ON mv.linked_movie_id = mh.movie_id
)

SELECT 
    mv.movie_id,
    mv.title,
    mv.production_year,
    COUNT(DISTINCT c.person_id) AS total_cast,
    ARRAY_AGG(DISTINCT a.name) AS actors,
    AVG(CASE WHEN mi.info IS NOT NULL THEN CAST(mi.info AS FLOAT) ELSE NULL END) AS avg_rating,
    FIRST_VALUE(ci.kind) OVER (PARTITION BY mv.movie_id ORDER BY ci.kind DESC) AS top_cast_type,
    COUNT(DISTINCT k.keyword) AS unique_keywords
FROM 
    movie_hierarchy mv
LEFT JOIN 
    complete_cast cc ON mv.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_info mi ON mv.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
LEFT JOIN 
    movie_keyword mk ON mv.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    comp_cast_type ci ON c.role_id = ci.id
WHERE 
    mv.production_year IS NOT NULL
GROUP BY 
    mv.movie_id, mv.title, mv.production_year
HAVING 
    COUNT(DISTINCT c.person_id) > 2
ORDER BY 
    mv.production_year DESC, total_cast DESC;
