WITH RecursiveTitleCTE AS (
    SELECT
        t.id,
        t.title,
        t.production_year,
        t.kind_id,
        t.imdb_index,
        t.season_nr,
        t.episode_nr
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
    UNION ALL
    SELECT
        t.id,
        t.title,
        t.production_year,
        t.kind_id,
        t.imdb_index,
        t.season_nr,
        t.episode_nr
    FROM
        aka_title t
    INNER JOIN RecursiveTitleCTE rt ON t.id = rt.id + 1
    WHERE
        t.production_year IS NOT NULL
),
CompanyCountCTE AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id
),
MovieKeywordCTE AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
CompleteCastCTE AS (
    SELECT
        cc.movie_id,
        STRING_AGG(c.name, ', ') AS complete_cast
    FROM
        complete_cast cc
    JOIN
        cast_info ci ON cc.subject_id = ci.id
    JOIN
        name c ON ci.person_id = c.id
    GROUP BY
        cc.movie_id
)
SELECT
    rt.title,
    rt.production_year,
    COALESCE(cc.company_count, 0) AS total_companies,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CC.complete_cast,
    ROW_NUMBER() OVER (PARTITION BY rt.production_year ORDER BY rt.production_year DESC) AS year_rank,
    MAX(ci.nr_order) OVER (PARTITION BY rt.id) AS max_role_order,
    rt.imdb_index,
    (SELECT COUNT(*) FROM aka_name an WHERE an.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = rt.id)) AS actor_count,
    (SELECT COUNT(DISTINCT ci.role_id) FROM cast_info ci WHERE ci.movie_id = rt.id) AS distinct_roles
FROM
    RecursiveTitleCTE rt
LEFT JOIN
    CompanyCountCTE cc ON rt.id = cc.movie_id
LEFT JOIN
    MovieKeywordCTE mk ON rt.id = mk.movie_id
LEFT JOIN
    CompleteCastCTE CC ON rt.id = CC.movie_id
WHERE
    rt.production_year >= 2000
    AND (rt.kind_id IS NULL OR rt.kind_id <= 5)
ORDER BY
    rt.production_year DESC,
    total_companies DESC NULLS LAST,
    year_rank;
