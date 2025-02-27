
WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title AS title_name,
        t.production_year,
        COUNT(ci.person_id) AS cast_count
    FROM
        title t
    JOIN
        movie_companies mc ON mc.movie_id = t.id
    JOIN
        company_name cn ON cn.id = mc.company_id
    JOIN
        cast_info ci ON ci.movie_id = t.id
    WHERE
        cn.country_code = 'USA'
    GROUP BY
        t.id, t.title, t.production_year
),
FilteredKeywords AS (
    SELECT
        mk.movie_id,
        k.keyword
    FROM
        movie_keyword mk
    JOIN
        keyword k ON k.id = mk.keyword_id
    WHERE
        LOWER(k.keyword) LIKE '%action%'
),
TitleWithKeywords AS (
    SELECT
        rt.title_id,
        rt.title_name,
        COUNT(fk.keyword) AS keyword_count
    FROM
        RankedTitles rt
    LEFT JOIN
        FilteredKeywords fk ON fk.movie_id = rt.title_id
    GROUP BY
        rt.title_id, rt.title_name
),
FinalRankings AS (
    SELECT
        tw.title_id,
        tw.title_name,
        rt.cast_count,
        tw.keyword_count,
        RANK() OVER (ORDER BY rt.cast_count DESC, tw.keyword_count DESC) AS ranking
    FROM
        TitleWithKeywords tw
    JOIN
        RankedTitles rt ON rt.title_id = tw.title_id
)
SELECT
    r.ranking,
    r.title_name,
    r.cast_count,
    r.keyword_count
FROM
    FinalRankings r
WHERE
    r.ranking <= 10
ORDER BY
    r.ranking;
