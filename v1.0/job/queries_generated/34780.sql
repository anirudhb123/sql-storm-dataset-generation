WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedMovies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(*) OVER (PARTITION BY mh.production_year) AS link_count,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS rn
    FROM
        MovieHierarchy mh
),
FilteredMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.link_count
    FROM
        RankedMovies rm
    WHERE
        rm.link_count > 1
        AND rm.rn <= 5
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(cn.name, ', ') AS companies
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id
)
SELECT
    fm.movie_id,
    fm.title,
    fm.production_year,
    COALESCE(ci.companies, 'No Companies') AS companies_info
FROM
    FilteredMovies fm
LEFT JOIN
    CompanyInfo ci ON fm.movie_id = ci.movie_id
ORDER BY
    fm.production_year DESC, fm.title
LIMIT 10;
