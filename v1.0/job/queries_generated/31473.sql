WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        t.title,
        0 AS level
    FROM
        aka_title t
    INNER JOIN
        movie_link ml ON t.id = ml.movie_id
    INNER JOIN
        title m ON ml.linked_movie_id = m.id
    WHERE
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT
        m.id,
        mh.title,
        level + 1
    FROM
        MovieHierarchy mh
    INNER JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    INNER JOIN
        title m ON ml.linked_movie_id = m.id
)
SELECT
    ma.name AS ActorName,
    t.title AS MovieTitle,
    th.production_year AS Year,
    COUNT(DISTINCT ci.role_id) AS NumberOfRoles,
    AVG(CASE WHEN pi.info IS NOT NULL THEN LENGTH(pi.info) ELSE 0 END) AS AvgInfoLength,
    STRING_AGG(k.keyword, ', ') AS Keywords
FROM
    aka_name ma
LEFT JOIN
    cast_info ci ON ma.person_id = ci.person_id
LEFT JOIN
    title t ON ci.movie_id = t.id
LEFT JOIN 
    MovieHierarchy mh ON mh.movie_id = t.id
LEFT JOIN
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN
    person_info pi ON ma.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'bio')
LEFT JOIN
    aka_title th ON t.id = th.movie_id
WHERE
    th.production_year IS NOT NULL
    AND (ma.name IS NOT NULL OR ma.name_pcode_nf IS NOT NULL)
GROUP BY
    ma.name, t.title, th.production_year
HAVING
    COUNT(DISTINCT ci.role_id) > 2
ORDER BY
    AVG(CASE WHEN pi.info IS NOT NULL THEN LENGTH(pi.info) ELSE 0 END) DESC,
    ma.name ASC;
