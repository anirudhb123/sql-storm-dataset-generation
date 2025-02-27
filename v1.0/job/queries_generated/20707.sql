WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
CorrelatedSubquery AS (
    SELECT
        ci.movie_id,
        (SELECT COUNT(*) FROM cast_info c WHERE c.movie_id = ci.movie_id AND c.note IS NOT NULL) AS non_null_cast_count
    FROM
        complete_cast ci
    GROUP BY
        ci.movie_id
),
MovieDetails AS (
    SELECT
        m.id AS movie_id,
        m.title,
        MAX(m.year) AS latest_year,
        COALESCE(SUM(mk.keyword IS NOT NULL::int), 0) AS keyword_count,
        COALESCE(SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END), 0) AS info_type_one_count
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        movie_info mi ON m.id = mi.movie_id
    GROUP BY
        m.id, m.title
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT c.name) AS company_count
    FROM
        movie_companies mc
    LEFT JOIN
        company_name c ON mc.company_id = c.id
    WHERE
        c.country_code IS NOT NULL
    GROUP BY
        mc.movie_id
)
SELECT
    mt.title_id,
    mt.title AS movie_title,
    mt.production_year,
    COALESCE(cd.company_count, 0) AS total_companies,
    COALESCE(sub.non_null_cast_count, 0) AS non_null_casts,
    CASE 
        WHEN mt.production_year < 2000 THEN 'Pre-2000' 
        WHEN mt.production_year BETWEEN 2000 AND 2010 THEN '2000s' 
        ELSE 'Post-2010' 
    END AS production_period
FROM
    RankedTitles mt
LEFT JOIN
    CorrelatedSubquery sub ON mt.title_id = sub.movie_id
LEFT JOIN
    CompanyDetails cd ON mt.title_id = cd.movie_id
WHERE 
    EXISTS (
        SELECT 1
        FROM movie_info mi
        WHERE mi.movie_id = mt.title_id
        AND mi.info IS NOT NULL
    )
AND 
    (mt.title LIKE '%Adventure%' OR mt.title LIKE '%Drama%')
ORDER BY
    mt.production_year DESC,
    non_null_casts DESC,
    mt.title_rank;
