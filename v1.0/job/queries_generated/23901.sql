WITH RankedTitles AS (
    SELECT
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS year_rank,
        COUNT(DISTINCT k.id) OVER (PARTITION BY t.id) AS keyword_count
    FROM
        aka_title t
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
), 
FilteredTitles AS (
    SELECT
        rt.title,
        rt.production_year,
        rt.keyword,
        rt.keyword_count
    FROM
        RankedTitles rt
    WHERE
        rt.year_rank = 1 AND
        rt.production_year >= 2000 AND
        (rt.keyword IS NULL OR LENGTH(rt.keyword) < 8)
), 
CastStats AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_member_count,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS note_count
    FROM
        cast_info ci
    GROUP BY
        ci.movie_id
), 
CombinedData AS (
    SELECT
        ft.title,
        ft.production_year,
        ft.keyword,
        cs.cast_member_count,
        cs.note_count
    FROM
        FilteredTitles ft
    LEFT JOIN
        CastStats cs ON ft.production_year = cs.cast_member_count
    WHERE
        ft.production_year IS NOT NULL
)
SELECT
    cd.title,
    cd.production_year,
    COALESCE(cd.keyword, 'No Keywords') AS keyword,
    cd.cast_member_count,
    cd.note_count,
    CASE
        WHEN cd.cast_member_count > 10 THEN 'Large Cast'
        WHEN cd.cast_member_count BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM
    CombinedData cd
WHERE
    cd.cast_member_count IS NOT NULL
ORDER BY
    cd.production_year DESC, 
    cd.cast_member_count DESC
LIMIT 100;
