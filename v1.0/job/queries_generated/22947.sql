WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id as movie_id,
        mt.title as movie_title,
        mt.production_year,
        COALESCE(CAST(NULLIF(mt.season_nr, 0) AS INTEGER), 1) AS season_number,
        COALESCE(CAST(NULLIF(mt.episode_nr, 0) AS INTEGER), 1) AS episode_number,
        1 AS level
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        at.production_year,
        COALESCE(CAST(NULLIF(at.season_nr, 0) AS INTEGER), 1),
        COALESCE(CAST(NULLIF(at.episode_nr, 0) AS INTEGER), 1) AS episode_number,
        mh.level + 1
    FROM movie_link ml
    JOIN aka_title at ON ml.movie_id = at.id
    JOIN movie_hierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    ak.name AS actor_name,
    mt.movie_title,
    COUNT(dd.id) AS total_roles,
    AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE -1 END) AS avg_order,
    STRING_AGG(DISTINCT COALESCE(it.info, 'N/A'), ', ') AS movie_info,
    MAX(CASE WHEN mk.keyword IS NOT NULL THEN mk.keyword ELSE 'No Keyword' END) AS max_keyword,
    COUNT(DISTINCT mh.movie_id) AS movies_in_hierarchy,
    RANK() OVER (ORDER BY COUNT(dd.id) DESC) AS actor_rank
FROM aka_name ak
JOIN cast_info ci ON ak.person_id = ci.person_id
JOIN aka_title mt ON ci.movie_id = mt.id
LEFT JOIN movie_info mi ON mt.id = mi.movie_id
LEFT JOIN info_type it ON mi.info_type_id = it.id
LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN movie_hierarchy mh ON mt.id = mh.movie_id
LEFT JOIN dd_table_type dd ON dd.role_id = ci.role_id -- Assuming dd_table_type is constructed correctly
WHERE mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
  AND (ak.name NOT LIKE '%(voice)%' OR ak.name NOT IS DISTINCT FROM ak.name)
  AND EXTRACT(YEAR FROM CURRENT_DATE) - mt.production_year < 50
GROUP BY ak.name, mt.movie_title
HAVING COUNT(dd.id) > 1
ORDER BY actor_rank ASC, total_roles DESC;

This SQL query incorporates various constructs as requested, including Common Table Expressions (CTEs) with a recursive structure to explore hierarchies, numerous JOINs (including LEFT JOINs with NULL logic), aggregate functions, conditional expressions, and window functions combined with correlated subqueries. It applies obscure predicates and seeks out corner cases with NULL handling as well as string aggregations to provide enriched context.
