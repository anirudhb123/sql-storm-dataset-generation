WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN
        aka_title m ON ml.linked_movie_id = m.id
    WHERE
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
)
SELECT
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT c.person_id) AS total_cast,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
    (SELECT COUNT(*) 
     FROM movie_keyword mk
     JOIN keyword k ON mk.keyword_id = k.id 
     WHERE mk.movie_id = m.id) AS keyword_count,
    AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY m.id) AS has_roles_ratio,
    COALESCE(MAX(CASE WHEN ci.note IS NOT NULL THEN ci.note END), 'No Notes') AS notes
FROM
    aka_title m
LEFT JOIN
    cast_info ci ON m.id = ci.movie_id
LEFT JOIN
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN
    MovieHierarchy mh ON m.id = mh.movie_id
WHERE
    m.production_year > 2000
    AND (EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = m.id 
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
    ) OR m.title LIKE '%Blockbuster%')
GROUP BY
    m.id, m.title, m.production_year
ORDER BY
    total_cast DESC,
    movie_title;
