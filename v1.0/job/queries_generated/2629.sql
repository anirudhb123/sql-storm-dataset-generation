WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY a.name) AS rank_per_year
    FROM
        aka_title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    WHERE
        k.keyword LIKE '%action%'
        AND t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT
        rm.*,
        COALESCE(CAST(m.movie_id AS VARCHAR), 'Unknown') AS movie_company,
        COUNT(DISTINCT ci.id) AS total_cast
    FROM
        RankedMovies rm
    LEFT JOIN
        movie_companies m ON rm.movie_id = m.movie_id
    LEFT JOIN
        cast_info ci ON rm.movie_id = ci.movie_id
    GROUP BY
        rm.movie_id, rm.title, rm.production_year
)
SELECT
    md.movie_id,
    md.title,
    md.production_year,
    md.movie_company,
    md.total_cast,
    CASE
        WHEN md.production_year < 2000 THEN 'Classic'
        WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_age_category
FROM
    MovieDetails md
WHERE
    md.rank_per_year <= 5
ORDER BY
    md.production_year DESC, md.total_cast DESC
LIMIT 15;
