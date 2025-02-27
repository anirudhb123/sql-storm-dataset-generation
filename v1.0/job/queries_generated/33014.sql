WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000
    UNION ALL
    SELECT
        mk.linked_movie_id AS movie_id,
        a.title,
        a.production_year,
        mh.level + 1
    FROM
        movie_link mk
    JOIN
        aka_title a ON mk.linked_movie_id = a.id
    JOIN
        movie_hierarchy mh ON mk.movie_id = mh.movie_id
),
company_cast AS (
    SELECT
        cc.movie_id,
        cc.person_id,
        p.name AS person_name,
        c.name AS company_name,
        ROW_NUMBER() OVER (PARTITION BY cc.movie_id ORDER BY cc.nr_order) AS rn
    FROM
        cast_info cc
    JOIN
        aka_name p ON cc.person_id = p.person_id
    LEFT JOIN
        movie_companies mc ON cc.movie_id = mc.movie_id
    LEFT JOIN
        company_name c ON mc.company_id = c.id
),
movie_info_complete AS (
    SELECT 
        m.movie_id,
        STRING_AGG(mi.info, ', ') AS info_details
    FROM
        movie_info mi
    JOIN 
        movie_hierarchy m ON mi.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
)
SELECT
    m.movie_id,
    m.title,
    m.production_year,
    COALESCE(ca.person_name, 'Unknown') AS cast_member,
    COALESCE(ca.company_name, 'Independent') AS production_company,
    mi.info_details,
    CASE 
        WHEN m.level = 0 THEN 'Original'
        ELSE 'Linked'
    END AS movie_type
FROM
    movie_hierarchy m
LEFT JOIN
    company_cast ca ON m.movie_id = ca.movie_id AND ca.rn = 1
LEFT JOIN
    movie_info_complete mi ON m.movie_id = mi.movie_id
WHERE
    m.production_year BETWEEN 2000 AND 2023
ORDER BY
    m.production_year DESC, m.title;
