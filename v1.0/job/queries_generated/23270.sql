WITH RankedMovies AS (
    SELECT
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast
    FROM
        aka_title AS t
    JOIN
        cast_info AS ci ON t.id = ci.movie_id
    GROUP BY
        t.title, t.production_year
),
TopRankedMovies AS (
    SELECT
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM
        RankedMovies AS rm
    WHERE
        rm.rank_by_cast = 1
),
MovieKeywords AS (
    SELECT
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        aka_title AS m
    JOIN
        movie_keyword AS mk ON m.id = mk.movie_id
    JOIN
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY
        m.id
),
MovieInfoWithNulls AS (
    SELECT
        m.id AS movie_id,
        mi.info,
        COALESCE(mi.note, 'No notes available') AS note
    FROM
        aka_title AS m
    LEFT JOIN
        movie_info AS mi ON m.id = mi.movie_id
),
DistinctCompanies AS (
    SELECT DISTINCT
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies AS mc
    JOIN
        company_name AS cn ON mc.company_id = cn.id
    JOIN
        company_type AS ct ON mc.company_type_id = ct.id
)
SELECT
    t.title,
    t.production_year,
    t.cast_count,
    mk.keywords,
    mwi.info AS movie_info,
    mwi.note,
    dc.company_name,
    dc.company_type
FROM
    TopRankedMovies AS t
LEFT JOIN
    MovieKeywords AS mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = t.title AND production_year = t.production_year LIMIT 1)
LEFT JOIN
    MovieInfoWithNulls AS mwi ON mwi.movie_id = (SELECT id FROM aka_title WHERE title = t.title AND production_year = t.production_year LIMIT 1)
LEFT JOIN
    DistinctCompanies AS dc ON dc.movie_id = (SELECT id FROM aka_title WHERE title = t.title AND production_year = t.production_year LIMIT 1)
WHERE
    t.production_year IS NOT NULL
    AND EXISTS (
        SELECT 1
        FROM cast_info ci
        JOIN aka_name an ON ci.person_id = an.person_id
        WHERE ci.movie_id = (SELECT id FROM aka_title WHERE title = t.title AND production_year = t.production_year LIMIT 1)
        AND an.name ILIKE '%John%'
    )
ORDER BY
    t.production_year DESC, t.cast_count DESC;
