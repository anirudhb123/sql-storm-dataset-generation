WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.imdb_index,
        1 AS depth
    FROM
        aka_title m
    WHERE
        m.production_year IS NOT NULL

    UNION ALL

    SELECT
        m.id,
        m.title,
        m.production_year,
        m.imdb_index,
        mh.depth + 1
    FROM
        aka_title m
    INNER JOIN movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
ActorCount AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM
        cast_info c
    GROUP BY
        c.movie_id
),
TitleKeywords AS (
    SELECT
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mt
    JOIN
        keyword k ON mt.keyword_id = k.id
    GROUP BY
        mt.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(ac.actor_count, 0) AS total_actors,
    COALESCE(tk.keywords, 'No Keywords') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS rank_within_year,
    CASE
        WHEN mh.depth = 1 THEN 'Direct'
        ELSE 'Linked'
    END AS movie_type
FROM
    MovieHierarchy mh
LEFT JOIN
    ActorCount ac ON mh.movie_id = ac.movie_id
LEFT JOIN
    TitleKeywords tk ON mh.movie_id = tk.movie_id
WHERE
    mh.production_year BETWEEN 2000 AND 2023
ORDER BY
    mh.production_year DESC,
    mh.title ASC;
