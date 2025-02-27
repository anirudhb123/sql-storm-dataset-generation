WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000

    UNION ALL

    SELECT
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN
        aka_title m ON ml.linked_movie_id = m.id
),

CastStats AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY
        ci.movie_id
),

MovieRatings AS (
    SELECT
        mi.movie_id,
        AVG(case when mi.info_type_id = 1 then mi.info::real else NULL end) AS avg_rating
    FROM
        movie_info mi
    GROUP BY
        mi.movie_id
)

SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    cs.total_cast,
    cs.actors,
    COALESCE(mr.avg_rating, 0) AS average_rating,
    CASE 
        WHEN mr.avg_rating IS NULL THEN 'No Rating'
        WHEN mr.avg_rating > 8 THEN 'Highly Rated'
        ELSE 'Average Rating'
    END AS rating_category,
    COUNT(DISTINCT ct.kind) AS company_count,
    MAX(m.production_year) FILTER (WHERE m.production_year IS NOT NULL) AS last_production_year
FROM
    MovieHierarchy mh
LEFT JOIN
    CastStats cs ON mh.movie_id = cs.movie_id
LEFT JOIN
    MovieRatings mr ON mh.movie_id = mr.movie_id
LEFT JOIN
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN
    company_type ct ON mc.company_type_id = ct.id
GROUP BY
    mh.movie_id, mh.title, mh.production_year, cs.total_cast, cs.actors, mr.avg_rating
ORDER BY
    average_rating DESC, mh.production_year DESC
LIMIT 10;
