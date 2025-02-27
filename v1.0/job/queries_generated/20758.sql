WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id as movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        1 as depth
    FROM
        title mt
    LEFT JOIN
        movie_link ml ON mt.id = ml.movie_id
    WHERE
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT
        mh.movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        mh.depth + 1
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN
        title mt ON ml.linked_movie_id = mt.id
    WHERE
        mh.depth < 10 -- limit the depth to avoid infinite loops
)
SELECT
    m.title AS movie_title,
    m.production_year,
    coalesce(a.name, 'Unknown Actor') AS actor_name,
    COUNT(c.id) AS actor_count,
    string_agg(DISTINCT k.keyword, ', ') AS keywords,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_present,
    CASE
        WHEN m.production_year < 2000 THEN 'Classic'
        WHEN m.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY m.production_year DESC) AS movie_rank
FROM
    MovieHierarchy mh
JOIN
    aka_title m ON mh.movie_id = m.id
LEFT JOIN
    cast_info c ON m.id = c.movie_id
LEFT JOIN
    aka_name a ON c.person_id = a.person_id
LEFT JOIN
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    movie_info mi ON m.id = mi.movie_id 
WHERE
    mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE 'Festivals%')
    AND m.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Drama%')
GROUP BY
    m.id, m.title, m.production_year, a.name
HAVING 
    COUNT(c.id) > 2
ORDER BY 
    m.production_year DESC,
    actor_count DESC;
