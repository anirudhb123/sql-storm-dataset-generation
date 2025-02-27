WITH RECURSIVE movie_hierarchy AS (
    -- CTE to build a hierarchy of movies based on linked movies
    SELECT 
        ml.movie_id AS root_movie_id,
        ml.linked_movie_id,
        1 AS depth
    FROM movie_link ml
    WHERE ml.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel') -- Assuming we link by "sequel"

    UNION ALL

    SELECT 
        mh.root_movie_id,
        ml.linked_movie_id,
        mh.depth + 1
    FROM movie_link ml
    INNER JOIN movie_hierarchy mh ON mh.linked_movie_id = ml.movie_id
    WHERE ml.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel')
),
movie_titles AS (
    -- CTE to gather titles and production years with outer join
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        COALESCE(aka.name, 'Unknown') AS aka_name
    FROM title t
    LEFT JOIN aka_title aka ON t.id = aka.movie_id
),
company_movie_info AS (
    -- CTE to get companies involved in the movies
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        GROUP_CONCAT(DISTINCT ct.kind ORDER BY ct.kind) AS company_types
    FROM movie_companies mc
    INNER JOIN company_name cn ON mc.company_id = cn.id
    INNER JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),
cast_performance AS (
    -- CTE to calculate average role order for each movie
    SELECT 
        ci.movie_id,
        AVG(ci.nr_order) AS avg_role_order
    FROM cast_info ci
    WHERE ci.note IS NOT NULL
    GROUP BY ci.movie_id
),
final_output AS (
    -- Final output combining all data
    SELECT 
        mt.title_id,
        mt.title,
        mt.production_year,
        mt.aka_name,
        cm.company_name,
        cm.company_types,
        COALESCE(ca.avg_role_order, 0) AS avg_role_order,
        mh.depth
    FROM movie_titles mt
    LEFT JOIN company_movie_info cm ON mt.title_id = cm.movie_id
    LEFT JOIN cast_performance ca ON mt.title_id = ca.movie_id
    LEFT JOIN movie_hierarchy mh ON mt.title_id = mh.root_movie_id
)
SELECT 
    title,
    production_year,
    aka_name,
    company_name,
    company_types,
    avg_role_order,
    CASE 
        WHEN depth IS NULL THEN 'No sequels'
        WHEN depth > 1 THEN CONCAT('Sequel Depth: ', depth)
        ELSE 'Direct Movie'
    END AS movie_relation
FROM final_output
WHERE production_year >= 2000
ORDER BY production_year DESC, avg_role_order ASC
LIMIT 100;
