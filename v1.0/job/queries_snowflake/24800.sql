WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS num_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS ranking
    FROM
        aka_title t
    JOIN
        cast_info ci ON t.id = ci.movie_id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY
        t.id, t.title, t.production_year
),
MoviesWithCompanyInfo AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        mco.company_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        rm.num_cast
    FROM
        RankedMovies rm
    LEFT JOIN
        movie_companies mco ON rm.movie_id = mco.movie_id
    LEFT JOIN
        company_name cn ON mco.company_id = cn.id
    LEFT JOIN
        company_type ct ON mco.company_type_id = ct.id
),
FilteredMovies AS (
    SELECT
        mwc.movie_id,
        mwc.title,
        mwc.production_year,
        COALESCE(mwc.company_name, 'Unknown Company') AS company_name,
        mwc.company_type,
        mwc.num_cast,
        CASE 
            WHEN mwc.num_cast >= 10 AND mwc.production_year = 2000 THEN 'Popular 2000s Movie'
            WHEN mwc.production_year IS NULL THEN 'Unreleased'
            ELSE 'Standard Movie'
        END AS movie_category
    FROM
        MoviesWithCompanyInfo mwc
    WHERE
        mwc.company_type IS NOT NULL OR mwc.num_cast IS NULL
)

SELECT 
    fm.title,
    fm.production_year,
    fm.company_name,
    fm.company_type,
    fm.num_cast,
    fm.movie_category,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = fm.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis') 
     LIMIT 1) AS has_synopsis
FROM 
    FilteredMovies fm
WHERE 
    (fm.movie_category = 'Popular 2000s Movie' AND fm.num_cast > 5) 
    OR (fm.num_cast IS NULL AND fm.company_name LIKE '%Star%')

ORDER BY 
    fm.production_year DESC,
    fm.num_cast DESC
LIMIT 20;
