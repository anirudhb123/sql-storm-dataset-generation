WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(c.person_id) AS cast_count
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    WHERE
        t.production_year IS NOT NULL
        AND t.production_year BETWEEN 2000 AND 2023
    GROUP BY
        t.id, t.title, t.production_year
),
TitleSummary AS (
    SELECT
        rt.production_year,
        COUNT(rt.title_id) AS total_titles,
        SUM(rt.cast_count) AS total_cast_members,
        AVG(rt.cast_count) AS avg_cast_per_title
    FROM
        RankedTitles rt
    GROUP BY
        rt.production_year
),
CompanyStats AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT co.name) AS unique_companies,
        MAX(co.country_code) AS prominent_country
    FROM
        movie_companies mc
    INNER JOIN
        company_name co ON mc.company_id = co.id
    GROUP BY
        mc.movie_id
),
FinalBenchmark AS (
    SELECT
        ts.production_year,
        ts.total_titles,
        ts.total_cast_members,
        ts.avg_cast_per_title,
        COALESCE(cs.unique_companies, 0) AS unique_company_count,
        cs.prominent_country
    FROM
        TitleSummary ts
    LEFT JOIN
        CompanyStats cs ON ts.total_titles = (SELECT COUNT(*) FROM aka_title WHERE production_year = ts.production_year)
)
SELECT
    fb.production_year,
    fb.total_titles,
    fb.total_cast_members,
    fb.avg_cast_per_title,
    fb.unique_company_count,
    fb.prominent_country,
    CASE 
        WHEN fb.total_cast_members IS NULL THEN 'N/A'
        WHEN fb.total_cast_members > 100 THEN 'Large Production'
        ELSE 'Small Production'
    END AS production_scale,
    STRING_AGG(DISTINCT ak.name, ', ') FILTER (WHERE ak.name IS NOT NULL) AS top_actors
FROM
    FinalBenchmark fb
LEFT JOIN
    cast_info ci ON ci.movie_id IN (SELECT id FROM aka_title WHERE production_year = fb.production_year)
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
GROUP BY
    fb.production_year, fb.total_titles, fb.total_cast_members, fb.avg_cast_per_title,
    fb.unique_company_count, fb.prominent_country
ORDER BY
    fb.production_year DESC;
