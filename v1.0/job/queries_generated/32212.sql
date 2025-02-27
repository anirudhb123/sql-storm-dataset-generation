WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id,
        c.movie_id,
        1 AS level
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name ILIKE 'John%' -- Starting point for actors named John

    UNION ALL

    SELECT 
        c.person_id,
        c.movie_id,
        h.level + 1
    FROM 
        cast_info c
    JOIN 
        ActorHierarchy h ON c.movie_id = h.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.person_id <> h.person_id -- Avoid self-referencing
)

SELECT 
    title.title,
    COUNT(DISTINCT ch.person_id) AS co_stars_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS co_stars_names,
    MAX(pi.info) AS top_keyword,
    COUNT(mi.info) AS movie_info_count
FROM 
    title 
LEFT JOIN 
    complete_cast cc ON title.id = cc.movie_id
LEFT JOIN 
    ActorHierarchy ah ON cc.subject_id = ah.person_id
LEFT JOIN 
    cast_info c ON ah.movie_id = c.movie_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_info mi ON title.id = mi.movie_id
LEFT JOIN 
    person_info pi ON c.person_id = pi.person_id
WHERE 
    title.production_year BETWEEN 2000 AND 2023
    AND EXISTS (SELECT 1 FROM movie_keyword mk WHERE mk.movie_id = title.id AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword ILIKE '%action%'))
GROUP BY 
    title.id
ORDER BY 
    co_stars_count DESC, 
    title.title;

