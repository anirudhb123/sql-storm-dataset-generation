WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        -- Getting the initial level of links
        ml.linked_movie_id,
        1 AS level
    FROM 
        title m
    LEFT JOIN 
        movie_link ml ON m.id = ml.movie_id

    UNION ALL

    SELECT 
        mh.movie_id,
        m.title,
        m.production_year,
        ml.linked_movie_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN 
        title m ON ml.linked_movie_id = m.id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(DISTINCT mc.company_id) AS total_companies,
    COUNT(DISTINCT mk.keyword_id) AS total_keywords,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    MAX(CASE WHEN mi.info_type_id = 1 THEN mi.info END) AS director_info,
    MAX(CASE WHEN mi.info_type_id = 2 THEN mi.info END) AS writer_info
FROM 
    MovieHierarchy mh
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    cast_info c ON mh.movie_id = c.movie_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
WHERE 
    mh.production_year >= 2000 
    AND (
        mh.title ILIKE '%action%'
        OR mi.info LIKE '%blockbuster%'
        OR ak.name IS NOT NULL
    )
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 2
ORDER BY 
    total_companies DESC, mh.production_year DESC;
