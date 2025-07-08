
WITH RecursiveMovie AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS rn
    FROM
        aka_title mt
    LEFT JOIN
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN
        company_type ct ON mc.company_type_id = ct.id
    WHERE
        mt.production_year IS NOT NULL
        AND mt.title IS NOT NULL
),
CastAggregate AS (
    SELECT
        ci.movie_id,
        COUNT(ci.person_id) AS total_cast,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names,
        SUM(CASE WHEN ci.nr_order IS NULL THEN 0 ELSE 1 END) AS ordered_cast_count,
        AVG(CASE WHEN ci.nr_order IS NULL THEN NULL ELSE ci.nr_order END) AS avg_order_position
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY
        ci.movie_id
),
FilteredMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.company_type,
        ca.total_cast,
        ca.cast_names,
        ca.ordered_cast_count,
        ca.avg_order_position
    FROM
        RecursiveMovie rm
    JOIN
        CastAggregate ca ON rm.movie_id = ca.movie_id
    WHERE
        rm.rn <= 10 AND
        (rm.company_type IS NOT NULL OR rm.production_year > 2000)
)
SELECT
    fm.title,
    fm.production_year,
    COALESCE(fm.company_type, 'Unknown') AS company_type,
    fm.total_cast,
    fm.cast_names,
    fm.ordered_cast_count,
    ROUND(fm.avg_order_position, 2) AS rounded_avg_order
FROM
    FilteredMovies fm
LEFT JOIN
    (SELECT DISTINCT movie_id FROM movie_info WHERE info_type_id = 1 AND LENGTH(info) > 20) mi
ON
    fm.movie_id = mi.movie_id
WHERE
    fm.total_cast > 0
ORDER BY
    fm.production_year DESC,
    fm.title;
