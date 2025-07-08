
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        a.title,
        a.production_year,
        mh.level + 1
    FROM 
        movie_link ml
        JOIN aka_title a ON a.id = ml.linked_movie_id
        JOIN MovieHierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    m.id AS movie_id,
    m.title,
    m.production_year,
    COALESCE(c.name, 'Unknown Company') AS production_company,
    (SELECT COUNT(DISTINCT cti.person_id)
     FROM cast_info cti 
     WHERE cti.movie_id = m.id) AS total_cast_count,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rn,
    LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
    AVG(CASE WHEN pi.info IS NOT NULL THEN CAST(pi.info AS DECIMAL) ELSE NULL END) AS average_rating
FROM 
    aka_title m
LEFT JOIN 
    movie_companies mc ON mc.movie_id = m.id
LEFT JOIN 
    company_name c ON c.id = mc.company_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = m.id AND mi.info_type_id = (SELECT id FROM info_type WHERE info ='rating' LIMIT 1)
LEFT JOIN 
    complete_cast cc ON cc.movie_id = m.id
LEFT JOIN 
    person_info pi ON pi.person_id = cc.subject_id
GROUP BY 
    m.id, m.title, m.production_year, c.name
HAVING 
    m.production_year >= 1990 AND m.production_year <= 2023
ORDER BY 
    total_cast_count DESC,
    m.title;
