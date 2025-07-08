
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank_by_cast,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names
    FROM
        aka_title t
    LEFT JOIN
        cast_info ci ON t.movie_id = ci.movie_id
    LEFT JOIN
        aka_name ak ON ci.person_id = ak.person_id
    WHERE
        t.production_year IS NOT NULL
        AND ak.name IS NOT NULL
    GROUP BY
        t.id, t.title, t.production_year
),
MovieCompanyData AS (
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
        ct.kind IS NOT NULL
),
FilteredMovies AS (
    SELECT
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.rank_by_cast,
        mcd.company_name,
        mcd.company_type
    FROM
        RankedMovies rm
    LEFT JOIN
        MovieCompanyData mcd ON rm.movie_id = mcd.movie_id
    WHERE
        rm.rank_by_cast <= 5 OR mcd.company_type IS NOT NULL
)
SELECT
    fm.movie_id,
    fm.movie_title,
    fm.production_year,
    COALESCE(fm.company_name, 'Independent') AS production_company,
    COALESCE(fm.company_type, 'N/A') AS company_type,
    CASE
        WHEN fm.rank_by_cast IS NULL THEN 'Unknown'
        ELSE CAST(fm.rank_by_cast AS TEXT)
    END AS cast_rank
FROM
    FilteredMovies fm
LEFT JOIN
    movie_info mi ON fm.movie_id = mi.movie_id
WHERE
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office' LIMIT 1) 
    AND (mi.info IS NOT NULL AND mi.info != '')
ORDER BY
    fm.production_year DESC, 
    fm.rank_by_cast ASC NULLS LAST;
