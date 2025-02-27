WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM title mt
    WHERE mt.production_year > 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM movie_link ml
    JOIN title t ON ml.linked_movie_id = t.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
, movie_cast AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ci.nr_order,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS cast_rank
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
)
, filtered_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT mc.company_id) AS num_companies,
        AVG(COUNT(".")) OVER() AS avg_cast_in_movie,
        mh.level
    FROM movie_hierarchy mh
    LEFT JOIN movie_companies mc ON mh.movie_id = mc.movie_id
    LEFT JOIN movie_cast mc2 ON mh.movie_id = mc2.movie_id
    GROUP BY mh.movie_id, mh.title, mh.production_year, mh.level
    HAVING COUNT(DISTINCT mc.company_id) > 1
)
SELECT 
    fm.title,
    fm.production_year,
    fm.num_companies,
    fm.avg_cast_in_movie,
    CASE 
        WHEN fm.level > 2 THEN 'High-level Movie'
        ELSE 'Regular Movie'
    END AS movie_type
FROM filtered_movies fm
ORDER BY fm.production_year DESC, fm.num_companies DESC;
