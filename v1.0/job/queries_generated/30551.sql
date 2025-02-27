WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.production_year IS NOT NULL

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM
        aka_title m
    JOIN MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),
MovieStats AS (
    SELECT
        m.movie_id,
        m.title,
        COUNT(c.person_id) AS cast_count,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        MAX(tc.kind) AS top_role,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS note_count,
        AVG(COALESCE(mi.info::integer, 0)) AS average_movie_info
    FROM
        MovieHierarchy m
    LEFT JOIN
        cast_info c ON m.movie_id = c.movie_id
    LEFT JOIN
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_info mi ON m.movie_id = mi.movie_id
    LEFT JOIN
        role_type tc ON c.role_id = tc.id
    GROUP BY
        m.movie_id, m.title
),
FinalStats AS (
    SELECT
        ms.movie_id,
        ms.title,
        ms.cast_count,
        ms.keyword_count,
        ms.top_role,
        ms.note_count,
        ms.average_movie_info,
        ROW_NUMBER() OVER (ORDER BY ms.average_movie_info DESC) AS rank
    FROM
        MovieStats ms
    WHERE
        ms.cast_count > 0
        AND ms.average_movie_info IS NOT NULL
)
SELECT
    f.movie_id,
    f.title,
    f.cast_count,
    f.keyword_count,
    f.top_role,
    f.note_count,
    f.average_movie_info,
    CASE 
        WHEN f.rank <= 10 THEN 'Top 10'
        WHEN f.rank <= 50 THEN 'Top 50'
        ELSE 'Other'
    END AS rank_category
FROM
    FinalStats f
WHERE
    f.cast_count > (SELECT AVG(cast_count) FROM FinalStats)
ORDER BY
    f.average_movie_info DESC, f.note_count DESC;
