
WITH MovieDetails AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        SUM(CASE WHEN k.keyword IS NOT NULL THEN 1 ELSE 0 END) AS keyword_count
    FROM
        aka_title m
    LEFT JOIN
        cast_info c ON m.id = c.movie_id
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        m.id, m.title, m.production_year
), RankedMovies AS (
    SELECT
        md.*,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.cast_count DESC) AS rn
    FROM
        MovieDetails md
)
SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.keyword_count,
    (SELECT AVG(cast_count) FROM MovieDetails) AS avg_cast_count,
    CASE
        WHEN rm.cast_count IS NULL THEN 'No Cast'
        ELSE 'Has Cast'
    END AS cast_status
FROM
    RankedMovies rm
WHERE
    rm.rn <= 5 AND
    rm.cast_count > (SELECT AVG(cast_count) FROM MovieDetails)
ORDER BY
    rm.production_year DESC,
    rm.cast_count DESC;
