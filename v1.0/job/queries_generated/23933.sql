WITH RECURSIVE title_hierarchy AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        t.episode_of_id,
        1 AS level
    FROM
        title t
    WHERE
        t.season_nr IS NULL

    UNION ALL

    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        t.episode_of_id,
        th.level + 1
    FROM
        title_hierarchy th
    JOIN title t ON t.episode_of_id = th.title_id
)
SELECT
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    STRING_AGG(DISTINCT th.title, '; ') AS titles,
    MAX(t.production_year) AS last_movie_year,
    ARRAY_AGG(DISTINCT mw.linked_movie_id) FILTER (WHERE mw.linked_movie_id IS NOT NULL) AS linked_movies,
    AVG(CASE WHEN a.name IS NULL THEN 0 ELSE 1 END) AS name_null_ratio,
    SUM(CASE WHEN c.nr_order IS NULL THEN 1 ELSE 0 END) AS missing_order_count,
    COUNT(DISTINCT CASE WHEN k.keyword = 'Award' THEN k.id END) AS awards_count
FROM
    aka_name a
LEFT JOIN
    cast_info c ON a.person_id = c.person_id
LEFT JOIN
    title t ON c.movie_id = t.id
LEFT JOIN
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    movie_link mw ON t.id = mw.movie_id
LEFT JOIN
    title_hierarchy th ON t.id = th.title_id
GROUP BY
    a.name
HAVING
    COUNT(DISTINCT c.movie_id) > 5
    AND MAX(t.production_year) >= 2000
    AND ARRAY_LENGTH(linked_movies, 1) IS NOT NULL
ORDER BY
    movie_count DESC,
    last_movie_year DESC
LIMIT 10 OFFSET 0;
