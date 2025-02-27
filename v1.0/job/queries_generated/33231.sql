WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        ml.linked_movie_id,
        1 AS hierarchy_level
    FROM
        title m
    LEFT JOIN movie_link ml ON m.id = ml.movie_id
    UNION ALL
    SELECT
        m.id AS movie_id,
        mh.title,
        mh.production_year,
        ml.linked_movie_id,
        mh.hierarchy_level + 1
    FROM
        movie_hierarchy mh
    JOIN movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN title m ON ml.linked_movie_id = m.id
),
movie_stats AS (
    SELECT
        t.title,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        MAX(mh.hierarchy_level) AS max_hierarchy_level
    FROM
        title t
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN movie_hierarchy mh ON t.id = mh.movie_id
    GROUP BY
        t.title
),
actor_info AS (
    SELECT
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS notable_appearances
    FROM
        aka_name a
    LEFT JOIN cast_info ci ON a.person_id = ci.person_id
    GROUP BY
        a.id, a.name
),
keyword_usage AS (
    SELECT
        t.id AS movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY
        t.id
)
SELECT
    m.title AS movie_title,
    m.production_year,
    m.actor_count,
    m.company_count,
    m.max_hierarchy_level,
    ai.actor_name,
    ai.movie_count,
    ai.notable_appearances,
    ku.keywords,
    CASE
        WHEN ai.notable_appearances > 0 THEN 'Notable'
        ELSE 'Regular'
    END AS actor_status
FROM
    movie_stats m
LEFT JOIN actor_info ai ON m.actor_count > 0 AND ai.movie_count > 0
LEFT JOIN keyword_usage ku ON ku.movie_id = m.movie_id
WHERE
    m.production_year BETWEEN 2000 AND 2023
ORDER BY
    m.production_year DESC, m.actor_count DESC, ai.notable_appearances DESC
LIMIT 50;
