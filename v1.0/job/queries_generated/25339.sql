WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        0 AS level, 
        NULL AS parent_movie_id
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000

    UNION ALL

    SELECT 
        m.linked_movie_id, 
        t.title, 
        t.production_year, 
        level + 1, 
        m.movie_id AS parent_movie_id
    FROM 
        movie_link m
    JOIN 
        aka_title t ON m.linked_movie_id = t.id
    JOIN 
        movie_hierarchy h ON m.movie_id = h.movie_id
)
SELECT 
    h.movie_id, 
    h.title, 
    h.production_year, 
    h.level,
    parent.title AS parent_title,
    (SELECT COUNT(*)
     FROM movie_keyword mk
     WHERE mk.movie_id = h.movie_id) AS keyword_count,
    (SELECT COUNT(*)
     FROM movie_companies mc
     WHERE mc.movie_id = h.movie_id) AS company_count,
    (SELECT STRING_AGG(DISTINCT cn.name, ', ') 
     FROM company_name cn
     JOIN movie_companies mc ON cn.id = mc.company_id
     WHERE mc.movie_id = h.movie_id) AS company_names,
    (SELECT STRING_AGG(DISTINCT pi.info, '; ') 
     FROM person_info pi
     JOIN cast_info ci ON pi.person_id = ci.person_id 
     WHERE ci.movie_id = h.movie_id) AS actor_info
FROM 
    movie_hierarchy h
LEFT JOIN 
    aka_title parent ON h.parent_movie_id = parent.id
ORDER BY 
    h.production_year DESC, 
    h.level, 
    h.title;
