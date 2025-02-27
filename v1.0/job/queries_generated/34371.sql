WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title AS title,
        0 AS level,
        NULL::integer AS parent_id
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        t.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        t.title AS title,
        mh.level + 1 AS level,
        mh.movie_id AS parent_id
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title t ON ml.linked_movie_id = t.id
)

SELECT 
    ah.name AS actor_name,
    mh.title AS movie_title,
    mh.level AS hierarchy_level,
    COUNT(DISTINCT m.id) OVER (PARTITION BY m.production_year) AS movies_per_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    MAX(pi.info) FILTER (WHERE it.info LIKE '%awards%') AS award_information
FROM 
    movie_hierarchy mh
JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
JOIN 
    aka_name ah ON ci.person_id = ah.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
LEFT JOIN 
    person_info pi ON ci.person_id = pi.person_id
WHERE 
    ah.name IS NOT NULL
GROUP BY 
    ah.name, mh.title, mh.level
HAVING 
    COUNT(DISTINCT k.id) > 0
ORDER BY 
    mh.level DESC, ah.name;

This query benchmarks performance by exploring a movie hierarchy through recursive common table expressions (CTEs), retrieving actor names associated with movies produced after the year 2000, while also calculating the number of movies per production year as a window function. It uses outer joins to include all potential information from various tables, applies string aggregation to collect keywords, and extracts award-related details based on specific filtering conditions. The results are grouped by actor name and movie title, ensuring that only those with associated keywords are included in the output.
