WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, mt.title, 0 AS depth
    FROM aka_title mt
    WHERE mt.production_year BETWEEN 1990 AND 2000

    UNION ALL

    SELECT m.movie_id, a.title, mh.depth + 1
    FROM movie_link m
    JOIN title a ON m.linked_movie_id = a.id
    JOIN movie_hierarchy mh ON mh.movie_id = m.movie_id
)

SELECT
    m.title AS movie_title,
    ARRAY_AGG(DISTINCT c.name ORDER BY c.name) AS cast_names,
    AVG(CASE WHEN cs.status_id IS NOT NULL THEN 1 ELSE NULL END) AS avg_cast_status,
    COUNT(DISTINCT k.keyword || '_' || COALESCE(k.phonetic_code, 'NA')) AS unique_keywords,
    COUNT(DISTINCT m_comp.company_id) FILTER (WHERE ct.kind = 'Distributor') AS distributor_count,
    COALESCE(MAX(mo.info), 'No Info') AS additional_info,
    SUM(CASE WHEN c.nr_order IS NULL THEN 0 ELSE 1 END) AS valid_cast_count
FROM
    movie_hierarchy m
LEFT JOIN
    complete_cast cs ON m.movie_id = cs.movie_id
LEFT JOIN
    cast_info c ON cs.subject_id = c.id
LEFT JOIN
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    movie_companies m_comp ON m.movie_id = m_comp.movie_id
LEFT JOIN
    company_type ct ON m_comp.company_type_id = ct.id
LEFT JOIN
    movie_info mo ON m.movie_id = mo.movie_id
WHERE
    m.depth < 3
    AND (m.title ILIKE '%adventure%' OR m.title ILIKE '%fantasy%')
GROUP BY
    m.title
HAVING
    COUNT(c.id) > 5
ORDER BY
    avg_cast_status DESC,
    unique_keywords DESC;
