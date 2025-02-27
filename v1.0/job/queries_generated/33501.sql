WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT
        mv.linked_movie_id,
        mv.title,
        mv.production_year,
        mh.level + 1
    FROM
        movie_link mv
    INNER JOIN
        MovieHierarchy mh ON mv.movie_id = mh.movie_id
    WHERE
        mh.level < 5
),
MovieStats AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        SUM(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget') THEN mi.info::numeric ELSE 0 END) AS total_budget,
        SUM(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Revenue') THEN mi.info::numeric ELSE 0 END) AS total_revenue,
        AVG(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating') THEN mi.info::numeric END) AS average_rating
    FROM
        MovieHierarchy mh
    LEFT JOIN
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN
        movie_companies mc ON mh.movie_id = mc.movie_id
    LEFT JOIN
        movie_info mi ON mh.movie_id = mi.movie_id
    GROUP BY
        mh.movie_id, mh.title, mh.production_year
)
SELECT
    ms.movie_id,
    ms.title,
    ms.production_year,
    ms.total_cast,
    ms.total_companies,
    ms.total_budget,
    ms.total_revenue,
    ms.average_rating,
    CASE 
        WHEN ms.total_revenue IS NULL OR ms.total_budget IS NULL THEN NULL
        ELSE (ms.total_revenue - ms.total_budget) / NULLIF(ms.total_budget, 0)
    END AS profit_margin
FROM
    MovieStats ms
WHERE
    ms.total_cast > 0
ORDER BY
    ms.average_rating DESC NULLS LAST,
    ms.total_revenue DESC;
