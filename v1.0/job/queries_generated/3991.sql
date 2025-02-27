WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(DISTINCT c.id) AS role_count
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        role_type r ON c.role_id = r.id
    GROUP BY
        c.movie_id, a.name, r.role
),
NullCheckMovies AS (
    SELECT
        m.movie_id,
        COUNT(m.subject_id) AS total_cast
    FROM
        complete_cast m
    GROUP BY
        m.movie_id
)
SELECT
    rm.title,
    rm.production_year,
    cd.actor_name,
    cd.role_name,
    cd.role_count,
    ncm.total_cast,
    CASE 
        WHEN ncm.total_cast IS NULL THEN 'No cast information available'
        ELSE 'Cast information available'
    END AS cast_info_status
FROM
    RankedMovies rm
LEFT JOIN
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    NullCheckMovies ncm ON rm.movie_id = ncm.movie_id
WHERE
    (cd.role_count > 1 OR ncm.total_cast IS NULL)
ORDER BY
    rm.production_year DESC,
    rm.rank;
