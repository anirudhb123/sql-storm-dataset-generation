WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM
        aka_title AS m
    WHERE
        m.production_year IS NOT NULL
    UNION ALL
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM
        movie_link AS ml
    JOIN movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
    JOIN aka_title AS m ON ml.linked_movie_id = m.id
),
actor_info AS (
    SELECT
        a.id AS actor_id,
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movies_count,
        STRING_AGG(DISTINCT at.title, ', ') AS movie_titles
    FROM
        aka_name AS ak
    JOIN cast_info AS ci ON ak.person_id = ci.person_id
    JOIN aka_title AS at ON ci.movie_id = at.id
    GROUP BY
        a.id, ak.name
),
company_summary AS (
    SELECT
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM
        movie_companies AS mc
    JOIN company_name AS c ON mc.company_id = c.id
    JOIN company_type AS ct ON mc.company_type_id = ct.id
    GROUP BY
        mc.movie_id, c.name, ct.kind
),
keyword_summary AS (
    SELECT
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        movie_keyword AS mk
    JOIN keyword AS k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(ai.actor_name, 'Unknown Actor') AS leading_actor,
    ai.movies_count,
    COALESCE(cs.company_name, 'No Companies') AS company_name,
    cs.company_type,
    cs.total_companies,
    COALESCE(ks.keywords, 'No Keywords') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS des_order,
    CASE
        WHEN mh.production_year < 2000 THEN 'Classic'
        WHEN mh.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era_classification
FROM
    movie_hierarchy AS mh
LEFT JOIN actor_info AS ai ON mh.movie_id = ai.movies_count
LEFT JOIN company_summary AS cs ON mh.movie_id = cs.movie_id
LEFT JOIN keyword_summary AS ks ON mh.movie_id = ks.movie_id
WHERE
    mh.movie_id IS NOT NULL
ORDER BY
    mh.production_year DESC,
    mh.title ASC;
