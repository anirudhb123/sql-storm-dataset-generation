
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY RANDOM()) AS random_rank,
        COUNT(DISTINCT ka.person_id) AS cast_count
    FROM
        aka_title t
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    LEFT JOIN aka_name ka ON ci.person_id = ka.person_id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY
        t.id, t.title, t.production_year
    HAVING
        COUNT(DISTINCT ka.person_id) > 0
),
DistinctCompanies AS (
    SELECT DISTINCT
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE
        c.country_code IS NOT NULL AND c.country_code <> ''
),
FilteredMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        dc.company_name,
        dc.company_type,
        rm.cast_count
    FROM
        RankedMovies rm
    LEFT JOIN DistinctCompanies dc ON rm.movie_id = dc.movie_id
    WHERE
        rm.random_rank <= 5 
    ORDER BY
        rm.production_year DESC,
        rm.cast_count DESC
)
SELECT
    fm.movie_id,
    fm.title,
    fm.production_year,
    COALESCE(fm.company_name, 'Independent') AS production_company,
    COALESCE(fm.company_type, 'Unknown') AS production_type,
    fm.cast_count,
    COUNT(DISTINCT ki.keyword) AS keyword_count,
    CASE
        WHEN fm.production_year < 2000 THEN 'Classic'
        WHEN fm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_era
FROM
    FilteredMovies fm
LEFT JOIN movie_keyword mk ON fm.movie_id = mk.movie_id
LEFT JOIN keyword ki ON mk.keyword_id = ki.id
GROUP BY
    fm.movie_id, fm.title, fm.production_year, fm.company_name, fm.company_type, fm.cast_count
ORDER BY
    fm.production_year DESC, fm.cast_count DESC, movie_era
LIMIT 100;
