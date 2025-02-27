WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT
        ml.linked_movie_id AS movie_id,
        at.title,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),

TopRatedMovies AS (
    SELECT
        m.id AS movie_id,
        AVG(r.rating) AS avg_rating
    FROM
        title m
    LEFT JOIN
        movie_info mi ON m.id = mi.movie_id AND mi.info_type_id =
            (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN
        (SELECT
            movie_id,
            CAST(info AS FLOAT) AS rating
         FROM movie_info
         WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'rating')) r ON m.id = r.movie_id
    GROUP BY
        m.id
    HAVING
        AVG(r.rating) >= 7.0
),

CompanyMovies AS (
    SELECT
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
)

SELECT
    mh.movie_id,
    mh.title,
    COALESCE(cm.company_name, 'Unknown') AS company_name,
    COALESCE(cm.company_type, 'Unknown') AS company_type,
    tr.avg_rating AS average_rating,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
FROM
    MovieHierarchy mh
LEFT JOIN
    TopRatedMovies tr ON mh.movie_id = tr.movie_id
LEFT JOIN
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN
    CompanyMovies cm ON mh.movie_id = cm.movie_id
LEFT JOIN
    aka_name ak ON ci.person_id = ak.person_id
WHERE
    mh.level = 1 -- Selecting only root level movies
GROUP BY
    mh.movie_id, mh.title, cm.company_name, cm.company_type, tr.avg_rating
ORDER BY
    tr.avg_rating DESC NULLS LAST, mh.title
LIMIT 10;
