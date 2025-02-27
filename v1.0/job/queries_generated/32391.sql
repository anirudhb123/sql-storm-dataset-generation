WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(t.production_year, 0) AS production_year,
        mt.kind AS movie_type,
        1 AS level
    FROM 
        aka_title t
    JOIN 
        kind_type mt ON t.kind_id = mt.id
    WHERE 
        t.production_year IS NOT NULL

    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        COALESCE(at.production_year, 0) AS production_year,
        kt.kind AS movie_type,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        kind_type kt ON at.kind_id = kt.id
    WHERE 
        mh.level < 5  -- Limit level for hierarchy traversal
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.movie_type,
    COUNT(DISTINCT cc.person_id) AS total_cast,
    COUNT(DISTINCT mc.company_id) AS total_companies,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS cast_with_notes,
    AVG(CASE WHEN ti.info IS NOT NULL AND ti.note LIKE '%review%' THEN ti.info::numeric ELSE NULL END) AS average_rating
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_info ti ON mh.movie_id = ti.movie_id AND ti.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') 
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.movie_type
ORDER BY 
    total_cast DESC, 
    average_rating DESC
LIMIT 50;
