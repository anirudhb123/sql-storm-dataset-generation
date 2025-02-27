WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        t.title,
        m.production_year,
        0 AS level
    FROM
        aka_title AS t
    JOIN
        movie_link AS ml ON ml.movie_id = t.id
    JOIN
        title AS m ON ml.linked_movie_id = m.id
    WHERE
        t.production_year >= 2000

    UNION ALL

    SELECT
        m.id AS movie_id,
        t.title,
        m.production_year,
        mh.level + 1
    FROM
        MovieHierarchy AS mh
    JOIN
        movie_link AS ml ON ml.movie_id = mh.movie_id
    JOIN
        title AS m ON ml.linked_movie_id = m.id
    JOIN
        aka_title AS t ON t.id = m.id
    WHERE
        t.production_year >= 2000
),

MovieStats AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        AVG(mi.info::numeric) AS avg_info_length,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS movie_rank
    FROM
        MovieHierarchy AS mh
    LEFT JOIN
        movie_companies AS mc ON mc.movie_id = mh.movie_id
    LEFT JOIN
        cast_info AS ci ON ci.movie_id = mh.movie_id
    LEFT JOIN
        movie_info AS mi ON mi.movie_id = mh.movie_id
    GROUP BY
        mh.movie_id, mh.title, mh.production_year, mh.level
)

SELECT 
    ms.title,
    ms.production_year,
    ms.company_count,
    ms.actor_count,
    ms.avg_info_length,
    CASE 
        WHEN ms.actor_count = 0 THEN 'No Cast'
        WHEN ms.actor_count < 5 THEN 'Limited Cast'
        ELSE 'Full Cast'
    END AS cast_type,
    COALESCE(ms.movie_rank, 'N/A') AS rank_in_level
FROM 
    MovieStats AS ms
WHERE 
    ms.company_count IS NOT NULL
ORDER BY 
    ms.production_year DESC, 
    ms.actor_count DESC;
