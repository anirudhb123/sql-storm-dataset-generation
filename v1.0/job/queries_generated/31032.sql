WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.level + 1
    FROM
        aka_title m
    JOIN MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),
CombinedData AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COALESCE(a.name, 'Unknown') AS actor_name,
        m.production_year,
        c.kind AS company_type,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY a.name) AS actor_order
    FROM
        aka_title m
    LEFT JOIN cast_info ci ON m.id = ci.movie_id
    LEFT JOIN aka_name a ON ci.person_id = a.person_id
    LEFT JOIN movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN company_type c ON mc.company_type_id = c.id
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
),
AggregatedData AS (
    SELECT
        movie_id,
        title,
        GROUP_CONCAT(DISTINCT actor_name ORDER BY actor_order) AS actor_names,
        MAX(production_year) AS latest_year,
        COUNT(DISTINCT company_type) AS total_company_types,
        COUNT(DISTINCT movie_keyword) AS total_keywords
    FROM
        CombinedData
    GROUP BY
        movie_id, title
),
FinalResults AS (
    SELECT
        *,
        CASE
            WHEN total_company_types > 2 THEN 'Diverse'
            ELSE 'Niche'
        END AS company_type_diversity,
        CASE
            WHEN latest_year IS NULL THEN 'No Year Data'
            ELSE CAST(latest_year AS VARCHAR)
        END AS year_info
    FROM
        AggregatedData
)
SELECT
    *
FROM
    FinalResults
WHERE
    actor_names IS NOT NULL
    AND year_info != 'No Year Data'
ORDER BY
    latest_year DESC, movie_id
LIMIT 100;
