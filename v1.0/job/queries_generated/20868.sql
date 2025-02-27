WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        t.title,
        COALESCE(
            c.role_id, 
            0  -- Default value if no role is found
        ) AS role_id,
        t.production_year,
        COALESCE(p.name, 'Unknown Actor') AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS row_num
    FROM
        aka_title t
    LEFT JOIN
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN
        cast_info c ON c.movie_id = cc.movie_id 
    LEFT JOIN
        aka_name p ON c.person_id = p.person_id
    WHERE
        t.production_year > 2000
    UNION ALL
    SELECT
        mh.movie_id,
        mh.title,
        mh.role_id,
        mh.production_year,
        mh.actor_name,
        mh.row_num
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON ml.movie_id = mh.movie_id
    WHERE
        mh.role_id IS NULL OR mh.role_id NOT IN (SELECT id FROM role_type WHERE role LIKE 'Extra%')
),
FilteredMovies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.actor_name,
        COUNT(DISTINCT c.id) AS cast_count,
        SUM(CASE WHEN c.note LIKE '%starring%' THEN 1 ELSE 0 END) AS starring_count
    FROM
        MovieHierarchy mh
    LEFT JOIN
        cast_info c ON c.movie_id = mh.movie_id
    GROUP BY
        mh.movie_id, mh.title, mh.production_year, mh.actor_name
),
RankedMovies AS (
    SELECT
        fm.*,
        RANK() OVER (PARTITION BY fm.production_year ORDER BY fm.starring_count DESC, fm.cast_count DESC) AS actor_rank
    FROM
        FilteredMovies fm
)

SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.actor_name,
    rm.cast_count,
    rm.starring_count,
    rm.actor_rank,
    CASE WHEN rm.starring_count = 0 THEN 'No starring actors' ELSE 'Has starring actors' END AS starring_status,
    COALESCE(NULLIF((SELECT AVG(cast_count) FROM FilteredMovies WHERE production_year = rm.production_year), 0), 'No casts available') AS average_cast_count
FROM
    RankedMovies rm
WHERE
    rm.actor_rank < 6  -- Top 5 actors by starring_count
ORDER BY
    rm.production_year DESC, rm.starring_count DESC;
