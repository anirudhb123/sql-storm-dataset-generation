WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        mt.id AS root_movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL

    SELECT 
        ml.linked_movie_id,
        sub_mt.title,
        sub_mt.production_year,
        mh.level + 1,
        mh.root_movie_id
    FROM 
        movie_link ml
    JOIN 
        aka_title sub_mt ON ml.linked_movie_id = sub_mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    m.title,
    m.production_year,
    COUNT(DISTINCT c.person_id) AS total_cast,
    STRING_AGG(DISTINCT a.name, ', ' ORDER BY a.name) AS cast_names,
    COUNT(DISTINCT k.keyword) AS total_keywords,
    COALESCE(i.info, 'No additional info') AS additional_info,
    ROW_NUMBER() OVER (PARTITION BY m.root_movie_id ORDER BY m.production_year DESC) AS movie_rank
FROM 
    MovieHierarchy m
LEFT JOIN 
    cast_info c ON m.movie_id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id
LEFT JOIN 
    info_type i ON mi.info_type_id = i.id
WHERE 
    m.production_year >= 2000
    AND (m.production_year <= 2021 OR m.production_year IS NULL)
GROUP BY 
    m.title, 
    m.production_year, 
    i.info
HAVING 
    COUNT(DISTINCT c.person_id) > 5
ORDER BY 
    m.production_year DESC, 
    total_cast DESC;
