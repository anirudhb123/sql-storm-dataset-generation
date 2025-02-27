WITH RankedMovies AS (
    SELECT
        at.movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS rn,
        COUNT(*) OVER (PARTITION BY at.production_year) AS movie_count
    FROM
        aka_title at
    WHERE
        at.production_year IS NOT NULL
),
Actors AS (
    SELECT
        ak.person_id,
        ak.name,
        ci.movie_id,
        ci.role_id,
        CASE
            WHEN ci.note IS NOT NULL THEN 'Noted Role'
            ELSE 'Standard Role'
        END AS role_description
    FROM
        aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
),
MoviesWithKeywords AS (
    SELECT
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN aka_title m ON mk.movie_id = m.id
    GROUP BY
        m.movie_id
)
SELECT
    rm.title,
    rm.production_year,
    rv.movie_count,
    a.name AS actor_name,
    a.role_description,
    mk.keywords AS movie_keywords
FROM
    RankedMovies rm
LEFT JOIN Actors a ON rm.movie_id = a.movie_id
LEFT JOIN MoviesWithKeywords mk ON rm.movie_id = mk.movie_id
WHERE
    rm.rn <= 5
ORDER BY
    rm.production_year DESC,
    rm.title ASC,
    a.name ASC NULLS LAST
UNION ALL
SELECT
    'Total Movies Produced In Year: ' || rm.production_year,
    NULL,
    SUM(rm.movie_count) OVER (PARTITION BY rm.production_year),
    'N/A',
    'N/A',
    'N/A'
FROM
    RankedMovies rm
GROUP BY
    rm.production_year
ORDER BY
    rm.production_year DESC;

