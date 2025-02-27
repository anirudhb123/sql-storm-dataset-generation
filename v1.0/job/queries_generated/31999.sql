WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::integer AS parent_id,
        0 AS level
    FROM
        aka_title AS mt
    WHERE
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT
        ep.id AS movie_id,
        ep.title,
        ep.production_year,
        mh.movie_id AS parent_id,
        mh.level + 1
    FROM
        aka_title AS ep
    JOIN
        MovieHierarchy AS mh ON ep.episode_of_id = mh.movie_id
),
TitleStats AS (
    SELECT
        mh.title,
        mh.production_year,
        COUNT(c.id) AS cast_count,
        AVG(COALESCE(mi.info_length, 0)) AS avg_info_length
    FROM
        MovieHierarchy AS mh
    LEFT JOIN
        complete_cast AS cc ON mh.movie_id = cc.movie_id
    LEFT JOIN (
        SELECT
            movie_id,
            LENGTH(info) AS info_length
        FROM
            movie_info
        WHERE
            info IS NOT NULL
    ) AS mi ON mh.movie_id = mi.movie_id
    GROUP BY
        mh.title,
        mh.production_year
),
TopTitles AS (
    SELECT
        title,
        production_year,
        cast_count,
        avg_info_length,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC, avg_info_length ASC) AS rn
    FROM
        TitleStats
)
SELECT
    tt.title,
    tt.production_year,
    tt.cast_count,
    tt.avg_info_length,
    CASE
        WHEN tt.cast_count >= 10 THEN 'High'
        WHEN tt.cast_count BETWEEN 5 AND 9 THEN 'Medium'
        ELSE 'Low'
    END AS classification
FROM
    TopTitles AS tt
WHERE
    tt.rn <= 20
ORDER BY
    tt.cast_count DESC, tt.avg_info_length ASC;

-- Optional outer join example demonstrating NULL logic
SELECT
    n.name AS actor_name,
    COALESCE(mt.title, 'No Movies Found') AS movie_title,
    COUNT(cc.id) AS movie_count
FROM
    name AS n
LEFT JOIN
    cast_info AS cc ON n.id = cc.person_id
LEFT JOIN
    aka_title AS mt ON cc.movie_id = mt.id
GROUP BY
    n.name, mt.title
HAVING
    COUNT(cc.id) > 0
ORDER BY
    movie_count DESC;

In this SQL query:

1. The first CTE `MovieHierarchy` recursively selects movies and their episodes, forming a hierarchy.
2. The second CTE `TitleStats` computes statistics about the cast and average info length for each title.
3. The third CTE `TopTitles` selects the top titles based on the number of cast members and average info length.
4. The final selection retrieves data about the top 20 titles with their classifications based on cast count.
5. An outer join example is included in a separate query that aggregates actor names with their associated movie counts, demonstrating the use of `COALESCE` to handle NULL movie titles.
