
WITH RankedTitles AS (
    SELECT
        a.id AS aka_id,
        a.person_id,
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS title_rank
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    JOIN
        aka_title t ON c.movie_id = t.movie_id
    WHERE
        t.production_year IS NOT NULL
        AND a.name IS NOT NULL
),
PopularKeywords AS (
    SELECT
        k.id AS keyword_id,
        k.keyword,
        COUNT(mk.movie_id) AS movie_count
    FROM
        keyword k
    JOIN
        movie_keyword mk ON k.id = mk.keyword_id
    GROUP BY
        k.id, k.keyword
    HAVING
        COUNT(mk.movie_id) > 10
),
FilteredCompanies AS (
    SELECT
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    WHERE
        c.country_code IS NOT NULL
        AND ct.kind LIKE 'Production%'
),
FinalSelection AS (
    SELECT
        rt.aka_id,
        rt.title,
        rt.production_year,
        pk.keyword,
        fc.company_name,
        fc.company_type
    FROM
        RankedTitles rt
    LEFT JOIN
        PopularKeywords pk ON rt.title_id IN (
            SELECT mk.movie_id FROM movie_keyword mk WHERE mk.keyword_id = pk.keyword_id
        )
    LEFT JOIN
        FilteredCompanies fc ON rt.title_id = fc.movie_id
    WHERE
        rt.title_rank = 1
        AND (rt.production_year < 2000 OR rt.production_year IS NULL)
    ORDER BY
        rt.production_year DESC
)

SELECT
    COUNT(*) AS total_titles,
    MIN(fs.production_year) AS earliest_title_year,
    MAX(fs.production_year) AS latest_title_year,
    LISTAGG(DISTINCT fs.company_name, ', ') AS production_companies,
    LISTAGG(DISTINCT fs.keyword, ', ') AS keywords_used
FROM
    FinalSelection fs
WHERE
    fs.company_type IS NOT NULL
GROUP BY
    fs.aka_id, fs.title, fs.production_year
HAVING
    COUNT(DISTINCT fs.keyword) >= 3
    AND MIN(fs.production_year) IS NOT NULL;
