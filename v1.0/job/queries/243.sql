WITH RankedMovies AS (
    SELECT
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rank_within_year
    FROM
        aka_title a
    WHERE
        a.production_year IS NOT NULL
),
CompanyCounts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT c.name) AS company_count
    FROM
        movie_companies mc
    JOIN
        company_name c ON mc.company_id = c.id
    GROUP BY
        mc.movie_id
),
MovieReviews AS (
    SELECT
        mi.movie_id,
        AVG(CASE WHEN it.info = 'review' THEN CAST(mi.info AS FLOAT) ELSE NULL END) AS avg_review_score
    FROM
        movie_info mi
    JOIN
        info_type it ON mi.info_type_id = it.id
    GROUP BY
        mi.movie_id
)
SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    cc.company_count,
    COALESCE(mr.avg_review_score, 0) AS average_review_score
FROM
    RankedMovies rm
LEFT JOIN
    CompanyCounts cc ON rm.movie_id = cc.movie_id
LEFT JOIN
    MovieReviews mr ON rm.movie_id = mr.movie_id
WHERE
    rm.rank_within_year <= 5
ORDER BY
    rm.production_year DESC,
    rm.title ASC;
