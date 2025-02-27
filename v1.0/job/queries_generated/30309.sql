WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        mv.id,
        mv.title,
        mv.production_year,
        mv.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mv ON ml.linked_movie_id = mv.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ah.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT ap.id) AS total_appearances,
    AVG(DISTINCT pw.actor_months) AS avg_months_active,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    MAX(CASE WHEN mv.level = 1 THEN 'Main' ELSE 'Supporting' END) AS role_type
FROM 
    aka_name ah
JOIN 
    cast_info ci ON ah.person_id = ci.person_id
JOIN 
    movie_hierarchy mv ON ci.movie_id = mv.movie_id
JOIN 
    aka_title at ON mv.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = at.id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN LATERAL (
    SELECT 
        mci.movie_id,
        COUNT(DISTINCT mci.*) AS actor_months
    FROM 
        complete_cast mci 
    WHERE 
        mci.subject_id = ah.id AND 
        mci.status_id IS NULL
    GROUP BY 
        mci.movie_id
) pw ON TRUE
WHERE 
    ah.name IS NOT NULL
GROUP BY 
    ah.name, at.title, at.production_year
HAVING 
    COUNT(DISTINCT at.id) > 2 AND 
    AVG(DISTINCT pw.actor_months) > 0
ORDER BY 
    total_appearances DESC
LIMIT 
    10;
