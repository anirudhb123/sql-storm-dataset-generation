WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        t.kind AS movie_type,
        COALESCE(c.id, 0) AS char_id,
        COALESCE(c.name, 'Unknown') AS char_name,
        1 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        kind_type t ON m.kind_id = t.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = m.id
    LEFT JOIN 
        char_name c ON c.id = ci.person_id
    WHERE 
        m.production_year > 2000
    
    UNION ALL
    
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.movie_type,
        COALESCE(c.id, 0) AS char_id,
        COALESCE(c.name, 'Unknown') AS char_name,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    LEFT JOIN 
        aka_title m2 ON ml.linked_movie_id = m2.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = m2.id
    LEFT JOIN 
        char_name c ON c.id = ci.person_id
    WHERE 
        mh.level < 5
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.movie_type,
        mh.char_id,
        mh.char_name,
        ROW_NUMBER() OVER (PARTITION BY mh.movie_type ORDER BY mh.production_year DESC) AS ranking,
        COUNT(mh.char_id) OVER (PARTITION BY mh.movie_id) AS char_count
    FROM 
        movie_hierarchy mh
)

SELECT 
    rm.title,
    rm.production_year,
    rm.movie_type,
    rm.char_name,
    rm.ranking,
    rm.char_count
FROM 
    ranked_movies rm
WHERE 
    rm.ranking <= 3
    AND rm.char_count > 1
    AND (rm.production_year IS NOT NULL OR rm.movie_type = 'Feature Film')
ORDER BY 
    rm.movie_type, 
    rm.production_year DESC,
    rm.char_count DESC;

-- Exception cases to demonstrate SQL NULL logic
SELECT 
    DISTINCT m.id,
    m.title,
    CASE 
        WHEN mc.company_id IS NULL THEN 'No Company'
        ELSE cn.name
    END AS company_name,
    CASE 
        WHEN mi.info IS NULL THEN 'No Info Available'
        ELSE mi.info
    END AS movie_info
FROM 
    aka_title m
LEFT JOIN 
    movie_companies mc ON mc.movie_id = m.id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON mi.movie_id = m.id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot' LIMIT 1)
WHERE 
    m.production_year < 1990
ORDER BY 
    m.title;

-- Bizarre corner case: testing with UNION ALL and NULL handling
SELECT 
    m.id AS movie_id,
    'Legacy Movie' AS source,
    m.title AS movie_title
FROM 
    aka_title m
WHERE 
    m.production_year < 1980

UNION ALL

SELECT 
    NULL,
    'Modern Movie' AS source,
    NULL AS movie_title
FROM 
    aka_title m
WHERE 
    m.production_year >= 1980 
EXCEPT 
SELECT 
    movie_id, 
    source, 
    movie_title 
FROM 
    (SELECT 
        NULL AS movie_id,
        'Unlinked Movie' AS source,
        'N/A' AS movie_title) AS n
ORDER BY 
    movie_title DESC;
