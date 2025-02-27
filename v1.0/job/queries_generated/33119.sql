WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id

    UNION ALL

    SELECT 
        mh.movie_id,
        at.title,
        at.production_year,
        ml.linked_movie_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        aka_title at ON mh.linked_movie_id = at.id
    LEFT JOIN 
        movie_link ml ON at.id = ml.movie_id
)

SELECT 
    mv.title AS movie_title,
    mv.production_year AS release_year,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    COUNT(DISTINCT cc.person_id) AS actor_count,
    AVG(pi.info IS NOT NULL::int) AS has_person_info_ratio,
    ROW_NUMBER() OVER (PARTITION BY mv.production_year ORDER BY mv.title) AS rank_within_year
FROM 
    MovieHierarchy mv
LEFT JOIN 
    movie_keyword mk ON mv.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON mv.movie_id = cc.movie_id
LEFT JOIN 
    person_info pi ON cc.subject_id = pi.person_id
WHERE 
    mv.production_year BETWEEN 1990 AND 2020
GROUP BY 
    mv.movie_id, mv.title, mv.production_year
ORDER BY 
    mv.production_year DESC, movie_title;
