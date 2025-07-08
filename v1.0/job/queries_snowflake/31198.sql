
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000

    UNION ALL

    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    m.title,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    LISTAGG(DISTINCT n.name, ', ') WITHIN GROUP (ORDER BY n.name) AS cast_names,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS cast_with_notes,
    AVG(m.production_year) OVER (PARTITION BY m.kind_id) AS avg_year_per_kind,
    MAX(m.production_year) OVER (PARTITION BY m.kind_id ORDER BY m.production_year DESC) AS latest_movie_year
FROM 
    MovieHierarchy m
LEFT JOIN 
    cast_info ci ON m.movie_id = ci.movie_id
LEFT JOIN 
    aka_name n ON ci.person_id = n.person_id
WHERE 
    m.production_year IS NOT NULL
GROUP BY 
    m.title,
    m.production_year,
    m.kind_id
HAVING 
    COUNT(DISTINCT ci.person_id) > 5 AND 
    AVG(m.production_year) < 2010
ORDER BY 
    total_cast DESC;
