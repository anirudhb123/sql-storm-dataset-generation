WITH RECURSIVE MovieHierarchy AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        0 AS level
    FROM title t
    WHERE t.kind_id = (
        SELECT id FROM kind_type WHERE kind = 'movie'
    )
    UNION ALL
    SELECT
        m.movie_id,
        tm.title,
        tm.production_year,
        mh.level + 1
    FROM movie_link m
    JOIN title tm ON m.linked_movie_id = tm.id
    JOIN MovieHierarchy mh ON m.movie_id = mh.movie_id
),
AggregatedMovies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        AVG(mo.info::numeric) AS average_rating
    FROM MovieHierarchy mh
    LEFT JOIN cast_info ci ON mh.movie_id = ci.movie_id
    LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN movie_info mo ON mh.movie_id = mo.movie_id
    WHERE mo.info_type_id = (
        SELECT id FROM info_type WHERE info = 'rating'
    )
    GROUP BY mh.movie_id, mh.title, mh.production_year
)
SELECT
    am.title,
    am.production_year,
    am.total_cast,
    am.actor_names,
    COALESCE(am.average_rating, 'N/A') AS average_rating,
    ct.kind AS company_type
FROM AggregatedMovies am
LEFT JOIN movie_companies mc ON am.movie_id = mc.movie_id
LEFT JOIN company_type ct ON mc.company_type_id = ct.id
WHERE am.production_year >= 2000
ORDER BY am.average_rating DESC NULLS LAST, am.total_cast DESC;

