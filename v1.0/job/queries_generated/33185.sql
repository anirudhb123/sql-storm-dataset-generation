WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level,
        CAST(m.title AS VARCHAR(255)) AS path
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000

    UNION ALL

    SELECT
        t.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1,
        CAST(mh.path || ' -> ' || at.title AS VARCHAR(255))
    FROM
        movie_link t
    JOIN 
        movie_hierarchy mh ON t.movie_id = mh.movie_id
    JOIN 
        aka_title at ON at.id = t.linked_movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    mh.path,
    COUNT(DISTINCT ci.person_id) AS total_actors,
    AVG(m.pricing) AS average_pricing,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    SUM(CASE
        WHEN ci.role_id IS NULL THEN 0
        ELSE 1
    END) AS roles_assigned
FROM
    movie_hierarchy mh
LEFT JOIN
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN
    movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN
    company_name cn ON mc.company_id = cn.id
LEFT JOIN
    (SELECT
        movie_id,
        -- Assume there is a pricing table that provides the pricing info
        SUM('some pricing logic here') AS pricing
     FROM
        movie_info
     WHERE
        info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
     GROUP BY
        movie_id) m ON mh.movie_id = m.movie_id
GROUP BY
    mh.movie_id, mh.title, mh.production_year, mh.level, mh.path
HAVING
    COUNT(DISTINCT ci.person_id) > 5
ORDER BY
    mh.production_year DESC, total_actors DESC;
