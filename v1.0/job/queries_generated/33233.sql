WITH RECURSIVE movie_tree AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        a.title AS movie_title,
        mt.depth + 1 AS depth
    FROM 
        movie_link ml
    INNER JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    INNER JOIN 
        movie_tree mt ON ml.movie_id = mt.movie_id
    WHERE 
        mt.depth < 3
)
SELECT 
    m.movie_id,
    m.movie_title,
    COALESCE(ct.kind, 'Unknown') AS company_type,
    CASE 
        WHEN cp.lookup_value IS NOT NULL THEN 'Yes' 
        ELSE 'No' 
    END AS has_person,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT ci.id) AS cast_count,
    AVG(COALESCE(mi.info, 0)) AS average_info_length,
    MIN(m.production_year) AS earliest_year
FROM 
    movie_tree m
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    cast_info ci ON m.movie_id = ci.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id
LEFT JOIN 
    (SELECT DISTINCT person_id, 'Lookup' AS lookup_value FROM person_info pi WHERE pi.info_type_id = 1) cp ON ci.person_id = cp.person_id
WHERE 
    m.depth <= 2
GROUP BY 
    m.movie_id, m.movie_title, company_type
ORDER BY 
    earliest_year DESC, m.movie_title
LIMIT 100;
