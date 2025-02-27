WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth,
        ARRAY[mt.title] AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        mv.id AS movie_id,
        mv.title,
        mv.production_year,
        mh.depth + 1,
        path || mv.title
    FROM 
        movie_link ml
    JOIN 
        aka_title mv ON ml.linked_movie_id = mv.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    m.title AS movie_title,
    m.production_year,
    ARRAY_AGG(DISTINCT c.name ORDER BY c.name) AS cast_names,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    MAX(CASE WHEN pi.info_type_id = 1 THEN pi.info END) AS genre,
    SUM(CASE WHEN mci.note IS NOT NULL THEN 1 ELSE 0 END) AS company_note_count,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.id) DESC) AS rank_by_cast
FROM 
    MovieHierarchy m
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id
LEFT JOIN 
    person_info pi ON c.person_id = pi.person_id
LEFT JOIN 
    movie_info_idx mii ON m.movie_id = mii.movie_id
WHERE 
    m.production_year >= 2000
GROUP BY 
    m.movie_id, m.title, m.production_year
HAVING 
    COUNT(DISTINCT c.id) > 2
ORDER BY 
    m.production_year DESC, keyword_count DESC;

This query constructs a recursive Common Table Expression (CTE) for hierarchical movie data linking, aggregates cast information and keywords, counts companies with notes, and utilizes window functions for ranking, providing a detailed benchmark based on production years and cast sizes.
