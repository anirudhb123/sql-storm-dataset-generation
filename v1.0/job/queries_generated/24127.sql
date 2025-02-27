WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) OVER (PARTITION BY t.id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') FILTER (WHERE ak.name IS NOT NULL) AS cast_names
    FROM
        aka_title AS t
    LEFT JOIN
        cast_info AS ci ON t.movie_id = ci.movie_id
    LEFT JOIN
        aka_name AS ak ON ci.person_id = ak.person_id
    WHERE
        t.production_year IS NOT NULL
),
CastRoles AS (
    SELECT
        rc.movie_id,
        rc.role_id,
        COUNT(DISTINCT ci.person_id) AS num_actors
    FROM
        cast_info AS ci
    JOIN
        role_type AS rc ON ci.role_id = rc.id
    GROUP BY
        rc.movie_id, rc.role_id
),
TopMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        rm.cast_names,
        RANK() OVER (ORDER BY rm.total_cast DESC) AS rank
    FROM
        RankedMovies AS rm
    WHERE
        rm.total_cast > 1
)

SELECT
    tm.title,
    tm.production_year,
    tm.total_cast,
    tm.cast_names,
    COALESCE(cr.num_actors, 0) AS unique_role_count,
    CASE
        WHEN tm.total_cast > 5 THEN 'Large Cast'
        WHEN tm.total_cast BETWEEN 3 AND 5 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM
    TopMovies AS tm
LEFT JOIN
    CastRoles AS cr ON tm.movie_id = cr.movie_id
WHERE
    tm.rank <= 10
ORDER BY
    tm.total_cast DESC,
    tm.production_year ASC;

SELECT
    DISTINCT m.title,
    COALESCE((
        SELECT COUNT(DISTINCT k.id)
        FROM movie_keyword AS mk
        JOIN keyword AS k ON mk.keyword_id = k.id
        WHERE mk.movie_id = m.id
    ), 0) AS keyword_count
FROM
    aka_title AS m
WHERE
    m.production_year IS NOT NULL
    AND m.kind_id IN (
        SELECT id FROM kind_type WHERE kind LIKE '%Drama%'
    )
    AND NOT EXISTS (
        SELECT 1
        FROM movie_info AS mi
        WHERE mi.movie_id = m.id AND mi.info_type_id IN (
            SELECT id FROM info_type WHERE info = 'Banned'
        )
    )
ORDER BY
    keyword_count DESC
LIMIT 20;
