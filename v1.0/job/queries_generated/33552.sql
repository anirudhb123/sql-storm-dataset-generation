WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT
        lm.linked_movie_id,
        lm.title,
        lm.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title lm ON ml.linked_movie_id = lm.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
CastStats AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        MAX(CASE WHEN rt.role = 'Lead' THEN ci.nr_order END) AS lead_order,
        MAX(CASE WHEN rt.role = 'Supporting' THEN ci.nr_order END) AS supporting_order
    FROM
        cast_info ci
    JOIN
        role_type rt ON ci.role_id = rt.id
    GROUP BY
        ci.movie_id
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    cs.total_cast,
    COALESCE(cs.lead_order, 0) AS lead_order,
    COALESCE(cs.supporting_order, 0) AS supporting_order,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COUNT(DISTINCT ic.id) AS info_count,
    MAX(CASE WHEN ci.note IS NOT NULL THEN 'Notes Available' ELSE 'No Notes' END) AS notes_status
FROM
    MovieHierarchy mh
LEFT JOIN
    CastStats cs ON mh.movie_id = cs.movie_id
LEFT JOIN
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN
    MovieKeywords mk ON mh.movie_id = mk.movie_id
LEFT JOIN
    complete_cast ic ON mh.movie_id = ic.movie_id
WHERE
    mh.production_year IS NOT NULL
GROUP BY
    mh.movie_id, mh.title, mh.production_year, cs.total_cast, cs.lead_order, cs.supporting_order, mk.keywords
ORDER BY
    mh.production_year DESC, cs.total_cast DESC
LIMIT 100;
