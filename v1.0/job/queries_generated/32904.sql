WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tvseries'))

    UNION ALL

    SELECT
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM
        movie_link ml
        JOIN aka_title mt ON ml.linked_movie_id = mt.id
        JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(a.name, 'Unknown Actor') AS actor_name,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    COUNT(DISTINCT cc.company_id) AS company_count,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY mh.production_year DESC) AS rn,
    COUNT(DISTINCT ci.person_role_id) AS role_type_count,
    CASE 
        WHEN mh.level = 1 THEN 'Original Movie'
        ELSE 'Related Movie'
    END AS movie_category
FROM
    movie_hierarchy mh
    LEFT JOIN cast_info ci ON mh.movie_id = ci.movie_id
    LEFT JOIN aka_name a ON ci.person_id = a.person_id
    LEFT JOIN movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc ON mh.movie_id = mc.movie_id
    LEFT JOIN company_name cc ON mc.company_id = cc.id
WHERE
    mh.production_year >= 2000
    AND (ci.note IS NULL OR ci.note NOT LIKE '%cameo%')
GROUP BY
    mh.movie_id, mh.title, mh.production_year, a.name, mh.level
ORDER BY
    mh.production_year DESC, movie_category, a.name NULLS LAST
LIMIT 50;
