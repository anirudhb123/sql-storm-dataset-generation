WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000 -- Starting point for the hierarchy

    UNION ALL

    SELECT 
        mv.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1 AS depth
    FROM 
        movie_link mv
    JOIN 
        title mt ON mv.linked_movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON mv.movie_id = mh.movie_id
    WHERE 
        mh.depth < 3 -- Limit depth to the hierarchy
)
SELECT 
    ah.name AS actor_name,
    mt.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    STRING_AGG(DISTINCT kc.keyword, ', ') AS keywords,
    RANK() OVER (PARTITION BY mt.kind_id ORDER BY mh.production_year DESC) AS rank_by_year,
    COALESCE(CAST(SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END) AS INTEGER), 0) AS total_info,
    COALESCE(MAX(mi.info) FILTER (WHERE mi.note IS NOT NULL), 'No Note') AS latest_info_note
FROM 
    movie_hierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    person_info pi ON cc.subject_id = pi.person_id
JOIN 
    aka_name ah ON pi.person_id = ah.person_id
JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
JOIN 
    aka_title mt ON mh.movie_id = mt.id
GROUP BY 
    ah.name, mt.title, mh.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 1 -- Only consider movies with more than one company
ORDER BY 
    rank_by_year, movie_title;
