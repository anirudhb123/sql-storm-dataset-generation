WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        NULL::integer AS parent_id,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.production_year IS NOT NULL

    UNION ALL

    SELECT
        m.id,
        m.title,
        m.production_year,
        mh.movie_id AS parent_id,
        mh.level + 1
    FROM
        aka_title m
    JOIN
        movie_link ml ON ml.linked_movie_id = m.id
    JOIN
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT
    h.movie_id,
    h.title,
    h.production_year,
    COALESCE(p.person_name, 'Unknown') as director,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    COUNT(DISTINCT c.person_id) OVER (PARTITION BY h.movie_id) AS total_cast,
    SUM(CASE WHEN c.note IS NULL THEN 1 ELSE 0 END) AS null_cast_notes,
    STRING_AGG(DISTINCT c.note, ', ') FILTER (WHERE c.note IS NOT NULL) AS non_null_notes,
    MAX(m_comp.company_name) FILTER (WHERE m_comp.company_type_id = ct.id) AS production_company
FROM
    movie_hierarchy h
LEFT JOIN
    movie_companies m_comp ON m_comp.movie_id = h.movie_id
LEFT JOIN
    company_name c_name ON c_name.id = m_comp.company_id
LEFT JOIN
    company_type ct ON ct.id = m_comp.company_type_id
LEFT JOIN
    cast_info c ON c.movie_id = h.movie_id
LEFT JOIN
    aka_name p ON p.person_id = c.person_id AND c.role_id IN (SELECT id FROM role_type WHERE role ILIKE '%Director%')
LEFT JOIN
    movie_keyword mk ON mk.movie_id = h.movie_id
LEFT JOIN
    keyword k ON k.id = mk.keyword_id
WHERE
    h.level <= 3
GROUP BY
    h.movie_id, h.title, h.production_year, p.person_name
ORDER BY
    h.production_year DESC,
    total_cast DESC;

This SQL query constructs a recursive Common Table Expression (CTE) to explore a hierarchy of movies and their related titles through `movie_link`. It gathers identifying information about movie production, cast, and keywords while applying various SQL constructs. The query also features aggregation functions for summarizing data and filters using `ARRAY_AGG` and `STRING_AGG` to demonstrate advanced string and NULL handling logic. The final results are ordered by production year and the number of cast members.
