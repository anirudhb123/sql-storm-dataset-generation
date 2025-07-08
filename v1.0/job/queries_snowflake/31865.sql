
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS depth
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        t.title,
        t.production_year,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title t ON ml.linked_movie_id = t.id
)

SELECT 
    p.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT mc.company_id) AS company_count,
    LISTAGG(DISTINCT c.kind, ', ') WITHIN GROUP (ORDER BY c.kind) AS company_kinds,
    ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY m.production_year DESC) AS rank,
    SUM(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count
FROM 
    cast_info ci
JOIN 
    aka_name p ON ci.person_id = p.person_id
JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
JOIN 
    aka_title m ON cc.subject_id = m.id
LEFT JOIN 
    movie_companies mc ON m.id = mc.movie_id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
WHERE 
    ci.nr_order IS NOT NULL
    AND p.name IS NOT NULL
    AND m.production_year >= 2000
    AND (c.kind IS NULL OR c.kind LIKE '%Production%')
GROUP BY 
    p.name, m.id, m.title, m.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) >= 2
ORDER BY 
    m.production_year DESC, p.name;
