WITH RankedTitles AS (
    SELECT
        a.id AS title_id,
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY length(a.title) DESC) AS title_rank
    FROM
        aka_title a
    WHERE
        a.production_year >= 2000
),
TitleKeywordCounts AS (
    SELECT
        m.id AS movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM
        movie_keyword mk
    JOIN
        aka_title m ON mk.movie_id = m.id
    GROUP BY
        m.id
),
FullCastDetails AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT ca.person_id) AS total_cast_members,
        STRING_AGG(DISTINCT CONCAT_WS(' ', an.name, an.surname_pcode), ', ') AS cast_names
    FROM
        cast_info c
    JOIN
        aka_name an ON c.person_id = an.person_id
    GROUP BY
        c.movie_id
),
DetailedInfo AS (
    SELECT
        t.title,
        t.production_year,
        t.kind_id,
        r.keyword_count,
        fc.total_cast_members,
        fc.cast_names
    FROM
        RankedTitles t
    LEFT JOIN
        TitleKeywordCounts r ON t.title_id = r.movie_id
    LEFT JOIN
        FullCastDetails fc ON t.title_id = fc.movie_id
)
SELECT
    di.title,
    di.production_year,
    kt.kind,
    di.keyword_count,
    di.total_cast_members,
    di.cast_names
FROM
    DetailedInfo di
JOIN
    kind_type kt ON di.kind_id = kt.id
WHERE
    di.keyword_count > 0
ORDER BY
    di.production_year DESC,
    di.keyword_count DESC;
