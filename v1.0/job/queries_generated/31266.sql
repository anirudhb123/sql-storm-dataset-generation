WITH RECURSIVE movie_hierarchy AS (
    -- Base case: Start with all titles
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        0 AS depth
    FROM 
        title t

    UNION ALL

    -- Recursive case: Join movie_link to find linked movies
    SELECT 
        ml.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        title t ON ml.linked_movie_id = t.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    COUNT(distinct c.id) AS total_cast,
    AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS avg_cast_with_notes,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COALESCE(cn.name, 'Unknown Company') AS production_company
FROM 
    movie_hierarchy m
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    aka_title ak ON ak.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.movie_id
LEFT JOIN 
    keyword kw ON kw.id = mk.keyword_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = m.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    m.production_year >= 2000 
    AND m.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'Feature%')
GROUP BY 
    m.movie_id, m.title, m.production_year, cn.name
ORDER BY 
    total_cast DESC, m.title;
