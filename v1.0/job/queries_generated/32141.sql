WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        mt.episode_of_id
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000
    UNION ALL
    SELECT
        mt2.id,
        mt2.title,
        mt2.production_year,
        mh.level + 1,
        mt2.episode_of_id
    FROM
        aka_title mt2
    JOIN MovieHierarchy mh ON mt2.episode_of_id = mh.movie_id
),
CastStatistics AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(CASE WHEN ci.note IS NULL THEN 1 END) AS unnamed_cast
    FROM
        cast_info ci
    GROUP BY
        ci.movie_id
),
TitleKeywords AS (
    SELECT
        mt.id AS movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM
        aka_title mt
    LEFT JOIN
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY
        mt.id
),
MovieCompanyInfo AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        COUNT(mc.id) AS company_count
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    cs.total_cast,
    cs.unnamed_cast,
    tk.keywords,
    co.companies,
    co.company_count,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY cs.total_cast DESC) AS rank
FROM
    MovieHierarchy mh
LEFT JOIN
    CastStatistics cs ON mh.movie_id = cs.movie_id
LEFT JOIN
    TitleKeywords tk ON mh.movie_id = tk.movie_id
LEFT JOIN
    MovieCompanyInfo co ON mh.movie_id = co.movie_id
WHERE
    cs.total_cast IS NOT NULL
ORDER BY
    mh.production_year DESC, rank
LIMIT 100;
