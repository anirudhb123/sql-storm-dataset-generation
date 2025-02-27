WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS hierarchy_level
    FROM
        aka_title mt
    WHERE
        mt.production_year > 2000

    UNION ALL

    SELECT
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.hierarchy_level + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedCast AS (
    SELECT
        ci.movie_id,
        ak.name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS cast_rank
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keyword_list
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    mh.movie_id,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT rc.name) AS total_cast,
    rk.keyword_list,
    MAX(rk.cast_rank) AS max_cast_rank,
    MIN(rk.cast_rank) AS min_cast_rank,
    CASE
        WHEN AVG(rk.cast_rank) IS NULL THEN 'No Cast Available'
        ELSE AVG(rk.cast_rank)::TEXT
    END AS average_cast_rank
FROM
    MovieHierarchy mh
LEFT JOIN
    RankedCast rk ON mh.movie_id = rk.movie_id
LEFT JOIN
    MovieKeywords mk ON mh.movie_id = mk.movie_id
GROUP BY
    mh.movie_id, mh.title, mh.production_year, mk.keyword_list
ORDER BY
    mh.production_year DESC, total_cast DESC;
