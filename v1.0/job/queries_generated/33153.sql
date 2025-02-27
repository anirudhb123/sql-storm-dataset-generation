WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(NULLIF(mk.keyword, ''), 'No Keywords') AS keyword,
        1 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        COALESCE(NULLIF(mk.keyword, ''), 'No Keywords') AS keyword,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        title mt ON ml.linked_movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id 
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
)
SELECT 
    h.title,
    h.production_year,
    h.keyword,
    COUNT(DISTINCT ca.person_id) AS cast_count,
    ARRAY_AGG(DISTINCT c.name) FILTER (WHERE c.name IS NOT NULL) AS cast_names,
    COUNT(DISTINCT COALESCE(CASE WHEN ci.note IS NOT NULL THEN ci.note END, 'No Note Available')) AS unique_notes 
FROM 
    movie_hierarchy h
LEFT JOIN 
    complete_cast cc ON h.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ca ON cc.subject_id = ca.person_id
LEFT JOIN 
    aka_name c ON c.person_id = ca.person_id
LEFT JOIN 
    movie_info mi ON h.movie_id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info ILIKE '%Award%')
WHERE 
    h.level <= 2
GROUP BY 
    h.title, h.production_year, h.keyword
ORDER BY 
    h.production_year DESC, cast_count DESC;
