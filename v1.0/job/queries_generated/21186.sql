WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COALESCE(n.name, 'Unknown') AS director_name,
        1 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name n ON c.person_id = n.person_id AND c.role_id = (SELECT id FROM role_type WHERE role = 'director')
    WHERE 
        m.production_year IS NOT NULL
    
    UNION ALL

    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        COALESCE(n.name, 'Unknown') AS director_name,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name n ON c.person_id = n.person_id AND c.role_id = (SELECT id FROM role_type WHERE role = 'director')
    WHERE 
        mh.level < 5 -- Limit recursion depth
)

SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    mh.director_name,
    COUNT(DISTINCT c.person_id) AS total_cast,
    STRING_AGG(DISTINCT k.keyword, ', ') FILTER (WHERE k.keyword IS NOT NULL) AS keywords,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY c.nr_order) AS cast_order
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_info c ON mh.movie_id = c.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    mh.movie_id, mh.movie_title, mh.production_year, mh.director_name
HAVING 
    COUNT(DISTINCT c.person_id) > 3 -- Filter for movies with more than 3 cast members
ORDER BY 
    mh.production_year DESC,
    total_cast DESC
LIMIT 50 OFFSET 0;

-- Additionally, demonstrate the handling of nulls and obscure edge cases.
SELECT 
    m.id AS movie_id,
    m.title AS movie_title,
    COALESCE(si.info, 'No information') AS summary_info,
    COALESCE(k.keyword, 'No keywords associated') AS movie_keyword
FROM 
    aka_title m
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON m.id = mc.movie_id
WHERE 
    m.production_year = (SELECT MAX(production_year) FROM aka_title) 
    AND (k.keyword IS NULL OR k.keyword NOT LIKE '%action%') -- Exclude 'action' keywords
ORDER BY 
    m.title;

-- Handle bizarre SQL semantics with NULLs and contextually confused relationships
SELECT
    CASE 
        WHEN m.id IS NULL THEN 'Movie Not Found'
        WHEN m.id IS NOT NULL AND c.person_id IS NULL THEN 'No Cast Information'
        ELSE 'Details Found'
    END AS status,
    m.title,
    COALESCE(n.name, 'Unknown') AS actor_name,
    COUNT(mc.id) AS company_count,
    COUNT(DISTINCT k.keyword) AS unique_keywords
FROM 
    aka_title m
LEFT JOIN 
    cast_info c ON m.id = c.movie_id
LEFT JOIN 
    aka_name n ON c.person_id = n.person_id
LEFT JOIN 
    movie_companies mc ON m.id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    m.id, m.title, n.name
HAVING 
    COUNT(mc.id) = 0 OR c.person_id IS NULL -- Examine relationships and nulls
ORDER BY 
    movie_count DESC;
