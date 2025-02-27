WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        t.title, 
        t.production_year, 
        1 AS level,
        NULL::integer AS parent_movie_id
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        c.country_code = 'USA'

    UNION ALL

    SELECT 
        m.id AS movie_id, 
        t.title, 
        t.production_year, 
        mh.level + 1, 
        mh.movie_id AS parent_movie_id
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title t ON ml.linked_movie_id = t.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        c.country_code <> 'USA'
)

SELECT 
    coalesce(h.title, 'Unknown') AS movie_title,
    h.production_year,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS noted_actors,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
    AVG(CASE WHEN h.level > 1 THEN h.level::numeric ELSE NULL END) AS avg_hierarchy_level
FROM 
    movie_hierarchy h
LEFT JOIN 
    complete_cast cc ON h.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    h.production_year IS NOT NULL
    AND (h.level IS NULL OR h.level >= 1)
GROUP BY 
    h.movie_title, h.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 0
ORDER BY 
    h.production_year DESC, 
    actor_count DESC
LIMIT 100;
