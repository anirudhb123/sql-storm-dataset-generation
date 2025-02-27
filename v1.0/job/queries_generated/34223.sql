WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    mv.title AS movie_title,
    mv.production_year,
    COUNT(DISTINCT km.keyword) AS keyword_count,
    SUM(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office') THEN CAST(mi.info AS numeric) ELSE 0 END) AS total_box_office,
    ROW_NUMBER() OVER (PARTITION BY mv.id ORDER BY total_box_office DESC) AS box_office_ranking
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    aka_title mv ON ci.movie_id = mv.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mv.id
LEFT JOIN 
    keyword km ON mk.keyword_id = km.id
LEFT JOIN 
    movie_info mi ON mv.id = mi.movie_id
WHERE 
    ak.name IS NOT NULL
    AND mv.production_year >= 2000
    AND mv.production_year < 2023
    AND (mi.info_type_id IS NULL OR mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office'))
GROUP BY 
    ak.name, mv.id, mv.title, mv.production_year
ORDER BY 
    mv.production_year DESC, keyword_count DESC
LIMIT 100;
