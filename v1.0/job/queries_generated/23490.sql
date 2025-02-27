WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        NULL AS parent_movie_id,
        1 AS depth
    FROM
        aka_title m
    WHERE
        m.production_year IS NOT NULL

    UNION ALL

    SELECT
        l.linked_movie_id AS movie_id,
        a.title,
        a.production_year,
        mh.movie_id AS parent_movie_id,
        mh.depth + 1
    FROM
        movie_link l
    JOIN aka_title a ON l.linked_movie_id = a.id
    JOIN movie_hierarchy mh ON l.movie_id = mh.movie_id
)

SELECT
    m.movie_id,
    m.title,
    m.production_year,
    mh.parent_movie_id,
    mh.depth,
    COUNT(DISTINCT c.id) AS cast_count,
    SUM(CASE WHEN p.info_type_id = 2 THEN 1 ELSE 0 END) AS gender_specific_cast_count,
    STRING_AGG(DISTINCT n.name, ', ') FILTER (WHERE n.gender = 'F') AS female_actors,
    STRING_AGG(DISTINCT n.name, ', ') FILTER (WHERE n.gender = 'M') AS male_actors
FROM
    movie_hierarchy m
LEFT JOIN complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN cast_info c ON cc.subject_id = c.person_id
LEFT JOIN person_info p ON p.person_id = c.person_id
LEFT JOIN name n ON n.id = c.person_id
GROUP BY
    m.movie_id, m.title, m.production_year, mh.parent_movie_id, mh.depth
HAVING
    COUNT(DISTINCT c.id) > 10
ORDER BY
    m.production_year DESC,
    m.title ASC;

-- Additional filter for unusual keyword associations
WITH keyword_associations AS (
    SELECT
        mk.movie_id,
        k.keyword,
        COUNT(*) AS keyword_count
    FROM
        movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id, k.keyword
    HAVING
        COUNT(*) > 5
)
SELECT
    m.movie_id,
    m.title,
    kw.keyword,
    kw.keyword_count
FROM
    aka_title m
JOIN keyword_associations kw ON m.id = kw.movie_id
WHERE
    m.production_year >= 2000
ORDER BY
    kw.keyword_count DESC;

-- Correlated subquery to find ranks of movies based on their 'cast_count'.
SELECT
    m.movie_id,
    m.title,
    (SELECT COUNT(*)
     FROM movie_hierarchy mh
     WHERE mh.cast_count > m.cast_count) + 1 AS rank
FROM (
    SELECT
        m.movie_id,
        COUNT(DISTINCT c.id) AS cast_count
    FROM
        movie_hierarchy m
    LEFT JOIN complete_cast cc ON m.movie_id = cc.movie_id
    LEFT JOIN cast_info c ON cc.subject_id = c.person_id
    GROUP BY
        m.movie_id
) AS m
ORDER BY
    rank ASC;

-- Here’s a query that deals with NULL logic
SELECT 
    c.note AS movie_note,
    COUNT(DISTINCT CASE WHEN cc.movie_id IS NOT NULL THEN cc.movie_id END) AS linked_movies,
    COALESCE(MAX(ci.info), 'No Info') AS info_text
FROM
    cast_info c
LEFT JOIN complete_cast cc ON c.movie_id = cc.movie_id
LEFT JOIN movie_info ci ON c.movie_id = ci.movie_id AND ci.info_type_id = 1
WHERE 
    c.note IS NOT NULL
GROUP BY 
    c.note
HAVING 
    COUNT(DISTINCT cc.movie_id) > 0
ORDER BY 
    movie_note;

