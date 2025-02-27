WITH RankedTitles AS (
    SELECT
        at.id AS title_id,
        at.title,
        at.production_year,
        COUNT(mk.id) AS keyword_count,
        ROW_NUMBER() OVER(PARTITION BY at.production_year ORDER BY COUNT(mk.id) DESC) AS rank
    FROM
        aka_title at
    LEFT JOIN
        movie_keyword mk ON at.movie_id = mk.movie_id
    GROUP BY
        at.id, at.title, at.production_year
),
PopularTitles AS (
    SELECT
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.keyword_count
    FROM
        RankedTitles rt
    WHERE
        rt.rank <= 10
),
ActedTitles AS (
    SELECT
        ct.movie_id,
        ARRAY_AGG(DISTINCT an.name) AS cast_names,
        COUNT(DISTINCT an.id) AS cast_count
    FROM
        cast_info ct
    JOIN
        aka_name an ON ct.person_id = an.person_id
    GROUP BY
        ct.movie_id
),
FinalResult AS (
    SELECT
        pt.title,
        pt.production_year,
        pt.keyword_count,
        coalesce(at.cast_names, ARRAY[]::text[]) AS cast_names,
        coalesce(at.cast_count, 0) AS cast_count
    FROM
        PopularTitles pt
    LEFT JOIN
        ActedTitles at ON pt.title_id = at.movie_id
)
SELECT
    title,
    production_year,
    keyword_count,
    cast_names,
    cast_count
FROM
    FinalResult
ORDER BY
    production_year DESC, keyword_count DESC;

This query identifies the top 10 highest keyword-count titles per production year, retrieves the cast names associated with those titles, and outputs the results. It uses Common Table Expressions (CTEs) for improved readability and maintainability.
