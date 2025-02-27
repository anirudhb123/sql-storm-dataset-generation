WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM
        aka_title AS m
    WHERE
        m.production_year IS NOT NULL

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        h.level + 1
    FROM
        movie_link AS ml
    INNER JOIN
        movie_hierarchy AS h ON ml.linked_movie_id = h.movie_id
    INNER JOIN
        aka_title AS m ON ml.movie_id = m.id
    WHERE
        h.level < 5
)

SELECT
    m.title AS Movie_Title,
    m.production_year AS Production_Year,
    COALESCE(cn.name, 'Unknown Company') AS Company_Name,
    COUNT(DISTINCT ci.person_id) AS Total_Cast_Members,
    SUM(CASE WHEN ci.role_id IS NULL THEN 1 ELSE 0 END) AS NULL_Role_Count,
    STRING_AGG(CONCAT(a.name, ' (', fn.coalesce(ki.keyword, 'No Keyword'), ')'), ', ') AS Cast_With_Keywords,
    ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY m.production_year DESC) AS Movie_Rank
FROM
    movie_companies AS mc
LEFT JOIN
    company_name AS cn ON mc.company_id = cn.id AND cn.country_code IS NOT NULL
JOIN
    complete_cast AS cc ON mc.movie_id = cc.movie_id
JOIN
    aka_title AS m ON cc.movie_id = m.id
LEFT JOIN
    cast_info AS ci ON cc.subject_id = ci.person_id
LEFT JOIN
    movie_keyword AS mk ON m.id = mk.movie_id
LEFT JOIN
    keyword AS ki ON mk.keyword_id = ki.id
LEFT JOIN
    aka_name AS a ON ci.person_id = a.person_id
WHERE
    m.production_year BETWEEN 2000 AND 2020
    AND (ci.nr_order IS NOT NULL OR a.name IS NOT NULL)
    AND (m.kind_id IS NULL OR EXISTS (SELECT 1 FROM kind_type WHERE id = m.kind_id AND kind = 'Feature'))
GROUP BY
    m.id,
    m.title,
    m.production_year,
    cn.name
HAVING
    COUNT(DISTINCT ci.person_id) > 1
ORDER BY
    Movie_Rank DESC,
    Total_Cast_Members DESC,
    Production_Year ASC;
