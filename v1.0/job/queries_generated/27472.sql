WITH RankedTitles AS (
    SELECT
        t.title,
        t.production_year,
        ak.name AS ak_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM
        aka_title t
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    JOIN
        aka_name ak ON mc.company_id = ak.person_id
    WHERE
        t.production_year >= 2000
        AND ak.name IS NOT NULL
),
CompleteCasting AS (
    SELECT
        t.title,
        t.production_year,
        COUNT(ci.id) AS total_cast,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names
    FROM
        title t
    LEFT JOIN
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN
        name c ON ci.person_id = c.imdb_id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.title, t.production_year
),
KeywordSummaries AS (
    SELECT
        t.title,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.title
)
SELECT
    rt.title,
    rt.production_year,
    rt.ak_name,
    rt.company_type,
    cc.total_cast,
    cc.cast_names,
    ks.keywords,
    rt.title_rank
FROM
    RankedTitles rt
LEFT JOIN
    CompleteCasting cc ON rt.title = cc.title AND rt.production_year = cc.production_year
LEFT JOIN
    KeywordSummaries ks ON rt.title = ks.title
ORDER BY
    rt.title_rank, rt.production_year DESC;
