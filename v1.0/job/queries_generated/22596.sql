WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(lt.linked_movie_id, -1) AS linked_movie_id,
        1 AS level
    FROM
        aka_title mt
    LEFT JOIN movie_link lt ON mt.id = lt.movie_id

    UNION ALL

    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(ml.linked_movie_id, -1) AS linked_movie_id,
        mh.level + 1
    FROM
        movie_hierarchy mh
    JOIN movie_link ml ON mh.linked_movie_id = ml.movie_id
)

SELECT
    ak.name AS actor_name,
    at.title AS movie_title,
    act.role_id,
    COUNT(DISTINCT movie_mv.movie_id) AS linked_movie_count,
    ARRAY_AGG(DISTINCT CASE WHEN mv.production_year IS NULL THEN 'UNKNOWN' ELSE mv.production_year::text END) AS production_years,
    MAX(CASE WHEN ak.name ILIKE '%Smith%' THEN 'YES' ELSE 'NO' END) AS contains_smith,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY COUNT(DISTINCT act.movie_id) DESC) AS role_rank
FROM
    aka_name ak
JOIN cast_info act ON ak.person_id = act.person_id
JOIN aka_title at ON act.movie_id = at.id
LEFT JOIN movie_hierarchy mh ON at.id = mh.movie_id
LEFT JOIN title mv ON mh.linked_movie_id = mv.id
WHERE
    at.production_year IS NOT NULL
    AND (ak.name IS NOT NULL OR ak.name != '')
    AND (mv.id IS NULL OR mv.production_year > 2000)
GROUP BY
    ak.person_id, at.title, act.role_id
HAVING
    COUNT(DISTINCT act.movie_id) > 1
    AND MIN(mh.level) < 3
ORDER BY
    linked_movie_count DESC,
    ak.name ASC;
