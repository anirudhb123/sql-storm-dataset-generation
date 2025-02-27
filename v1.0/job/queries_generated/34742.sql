WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year > 2000

    UNION ALL

    SELECT
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title m ON ml.movie_id = m.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedCast AS (
    SELECT
        ci.movie_id,
        ak.name,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) as rank
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    WHERE
        ci.person_role_id IN (SELECT id FROM role_type WHERE role IN ('Actor', 'Actress'))
),
FilteredMovies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT rc.name) AS actor_count
    FROM
        MovieHierarchy mh
    LEFT JOIN
        RankedCast rc ON mh.movie_id = rc.movie_id
    GROUP BY
        mh.movie_id, mh.title, mh.production_year
)
SELECT
    fm.title,
    fm.production_year,
    fm.actor_count,
    CASE 
        WHEN fm.actor_count > 0 THEN 'Has Actors'
        ELSE 'No Actors'
    END AS actor_presence,
    COALESCE(SUM(mo.info) FILTER (WHERE mo.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')), 0) AS box_office_info
FROM
    FilteredMovies fm
LEFT JOIN
    movie_info mo ON fm.movie_id = mo.movie_id
WHERE
    fm.production_year BETWEEN 2005 AND 2020
GROUP BY
    fm.title, fm.production_year, fm.actor_count
HAVING
    actor_count > 3
ORDER BY
    fm.production_year DESC, fm.actor_count DESC;
