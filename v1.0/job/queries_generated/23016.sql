WITH RECURSIVE movie_hierarchy AS (
    -- CTE to get a hierarchy of movies and their linked movies
    SELECT
        ml.movie_id,
        ml.linked_movie_id,
        1 AS level
    FROM
        movie_link ml
    WHERE
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'related')

    UNION ALL

    SELECT
        mh.movie_id,
        ml.linked_movie_id,
        mh.level + 1
    FROM
        movie_hierarchy mh
    JOIN movie_link ml ON mh.linked_movie_id = ml.movie_id
    WHERE
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'related') 
        AND mh.level < 5 -- Limit depth to 5 for performance
)

SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    array_agg(DISTINCT kw.keyword) AS keywords,
    COUNT(DISTINCT CASE WHEN mc.company_type_id IS NULL THEN mc.company_id END) AS no_company_types,
    SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS roles_with_notes,
    STRING_AGG(DISTINCT c.note, '; ') AS role_notes,
    AVG(COALESCE(mo.info_type_id, 0)) AS avg_info_type_id -- averaging over movie info type ids
FROM 
    aka_name a
JOIN 
    cast_info ci ON ci.person_id = a.person_id
JOIN 
    aka_title t ON t.id = ci.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = t.id
LEFT JOIN 
    movie_keyword mw ON mw.movie_id = t.id
LEFT JOIN 
    keyword kw ON kw.id = mw.keyword_id
LEFT JOIN 
    complete_cast cc ON cc.movie_id = t.id
LEFT JOIN 
    movie_info mo ON mo.movie_id = t.id
WHERE 
    (t.production_year BETWEEN 2000 AND 2023) 
    AND (kw.keyword IS NULL OR kw.keyword ILIKE '%thriller%') -- Bizarre and unusual semantical filtering
GROUP BY 
    a.name, t.title, t.production_year
HAVING 
    COUNT(DISTINCT ci.id) > 2 -- Actors must have at least 3 roles
ORDER BY 
    t.production_year DESC, 
    COUNT(DISTINCT ci.id) DESC
LIMIT 100
OFFSET 0;

-- Note:
-- The query utilizes a recursive CTE to build relationships between movies,
-- aggregates data including actors and movie titles, counts unique company types, 
-- uses string aggregation for notes, averages info type ids, and implements 
-- complex filtering logic while showcasing unusual semantics.
