WITH RECURSIVE MovieHierarchy AS (
    -- Base case: Start with all movies released after 2000
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year > 2000
    
    UNION ALL
    
    -- Recursive case: Join with linked movies to build hierarchy
    SELECT 
        m.linked_movie_id AS movie_id,
        a.title,
        a.production_year,
        mh.level + 1
    FROM 
        movie_link m
    JOIN 
        aka_title a ON m.linked_movie_id = a.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = m.movie_id
)

SELECT
    ti.title AS main_title,
    ti.production_year,
    COUNT(DISTINCT c.person_id) AS total_cast,
    STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
    SUM(CASE 
        WHEN ci.nr_order IS NULL THEN 0 
        ELSE ci.nr_order 
    END) AS total_order,
    MIN(cn.kind) AS company_kind,
    MAX(CASE WHEN ci.role_id IS NOT NULL THEN ci.role_id ELSE -1 END) AS max_role_id,
    AVG(mi.info::integer) AS average_movie_rating
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON cc.movie_id = mh.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name a ON a.person_id = ci.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
JOIN 
    aka_title ti ON mh.movie_id = ti.id
GROUP BY 
    ti.id, ti.title, ti.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 5 AND 
    MIN(mh.level) <= 2
ORDER BY 
    ti.production_year DESC,
    total_cast DESC
LIMIT 10;
