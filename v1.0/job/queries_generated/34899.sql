WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        0 AS level,
        NULL AS parent_id
    FROM
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') -- Base movies only
    
    UNION ALL
    
    SELECT
        mt.id AS movie_id,
        mt.title,
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM
        aka_title mt
    JOIN 
        movie_link ml ON mt.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.level,
    STRING_AGG(DISTINCT n.name, ', ') AS actor_names,
    STRING_AGG(DISTINCT c.name, ', ') AS company_names,
    COUNT(DISTINCT kw.keyword) AS keyword_count,
    AVG(COALESCE(mi.production_year, 0)) AS avg_production_year
FROM
    MovieHierarchy mh
LEFT JOIN
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN
    aka_name n ON ci.person_id = n.person_id
LEFT JOIN
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN
    company_name c ON mc.company_id = c.id
LEFT JOIN
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN
    aka_title mt ON mh.movie_id = mt.id
LEFT JOIN
    movie_info mi ON mt.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Production Year')
WHERE
    mh.level = 0
GROUP BY
    mh.movie_id, mh.title, mh.level
HAVING
    COUNT(DISTINCT n.person_id) > 2 -- Filter for movies with more than 2 actors
ORDER BY
    avg_production_year DESC,
    mh.title ASC;
This SQL query constructs a recursive common table expression (CTE) to gather a hierarchy of movies linked to each other. It then performs several outer joins to collect actors, companies, and keywords associated with each movie. It aggregates actor names and company names into comma-separated strings, counts distinct keywords, averages the production years, and applies filtering conditions and ordering.
