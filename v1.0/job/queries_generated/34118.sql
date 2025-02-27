WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        at.production_year >= 2000
)

SELECT 
    h.movie_id,
    h.title,
    h.production_year,
    ARRAY_AGG(DISTINCT c.kind) AS company_types,
    COUNT(DISTINCT ca.person_id) AS actor_count,
    AVG(pi.info::numeric) FILTER (WHERE pi.info_type_id = 1) AS average_rating,
    MAX(pi.note) FILTER (WHERE pi.info_type_id = 2) AS latest_note,
    STRING_AGG(DISTINCT CONCAT(a.name, ' (', a.name_pcode_nf, ')'), ', ') AS actor_names,
    COALESCE(NULLIF(h.production_year, 0), 'Unknown Year') AS year_output
FROM 
    movie_hierarchy h
LEFT JOIN 
    movie_companies mc ON mc.movie_id = h.movie_id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    cast_info ca ON ca.movie_id = h.movie_id
LEFT JOIN 
    aka_name a ON a.person_id = ca.person_id
LEFT JOIN 
    movie_info pi ON pi.movie_id = h.movie_id
WHERE 
    h.level <= 2
GROUP BY 
    h.movie_id, h.title, h.production_year
HAVING 
    COUNT(DISTINCT ca.person_id) > 1
ORDER BY 
    h.production_year DESC, h.title;
