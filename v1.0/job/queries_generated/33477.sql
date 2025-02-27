WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.depth + 1
    FROM 
        aka_title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id
    JOIN movie_hierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    mh.title AS movie_title,
    mh.production_year,
    COUNT(c.id) AS cast_count,
    AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_notes_ratio,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
    ROW_NUMBER() OVER (PARTITION BY mh.kind_id ORDER BY mh.depth DESC) AS kind_rank
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_info c ON mh.movie_id = c.movie_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    info_type it ON it.id = (SELECT MAX(info_type_id) FROM movie_info WHERE movie_id = mh.movie_id)
WHERE 
    mh.depth <= 3
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(c.id) > 5 AND MIN(mh.production_year) < 2010
ORDER BY 
    kind_rank, mh.production_year DESC;

-- Additional insights with NULL handling
WITH unlisted_companies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.name IS NULL OR ct.kind IS NULL
)

SELECT 
    mh.title,
    u.company_name,
    u.company_type
FROM 
    movie_hierarchy mh
LEFT JOIN 
    unlisted_companies u ON mh.movie_id = u.movie_id
ORDER BY 
    mh.production_year;
