WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000 
    UNION ALL
    SELECT
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN aka_title at ON ml.linked_movie_id = at.id
    WHERE
        mh.level < 3 
),
MovieKeywords AS (
    SELECT
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN aka_title m ON mk.movie_id = m.id
    GROUP BY
        m.movie_id
),
MovieInfo AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mi.info AS additional_info
    FROM
        aka_title mt
    LEFT JOIN movie_info mi ON mt.id = mi.movie_id
    WHERE
        mi.info IS NOT NULL
),
CastDetails AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM
        cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    GROUP BY
        ci.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    mk.keywords,
    mi.additional_info,
    cd.cast_count,
    cd.actors,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY mh.level) AS movie_rank
FROM
    MovieHierarchy mh
LEFT JOIN MovieKeywords mk ON mh.movie_id = mk.movie_id
LEFT JOIN MovieInfo mi ON mh.movie_id = mi.movie_id
LEFT JOIN CastDetails cd ON mh.movie_id = cd.movie_id
ORDER BY
    mh.production_year DESC,
    movie_rank
LIMIT 100;