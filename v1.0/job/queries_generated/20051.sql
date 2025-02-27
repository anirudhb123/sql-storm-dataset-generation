WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.imdb_index,
        0 AS level
    FROM title t
    WHERE t.production_year BETWEEN 1990 AND 2023

    UNION ALL

    SELECT 
        mt.linked_movie_id AS title_id,
        tt.title,
        tt.production_year,
        tt.imdb_index,
        mh.level + 1
    FROM movie_link mt
    JOIN movie_hierarchy mh ON mt.movie_id = mh.title_id
    JOIN title tt ON mt.linked_movie_id = tt.id
),

actor_earning AS (
    SELECT 
        c.person_id,
        SUM(CASE 
            WHEN c.nr_order IS NOT NULL THEN 1000 ELSE 0 END) AS earnings
    FROM cast_info c
    GROUP BY c.person_id
),

vivid_characters AS (
    SELECT 
        a.id AS actor_id,
        ak.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        MAX(mc.note) AS notable_role
    FROM aka_name ak
    JOIN cast_info c ON ak.person_id = c.person_id
    JOIN title t ON c.movie_id = t.id
    LEFT JOIN movie_companies mc ON c.movie_id = mc.movie_id
    GROUP BY a.id, ak.name
    HAVING COUNT(DISTINCT c.movie_id) > 5
),

assistant_earnings AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        ae.earnings
    FROM vivid_characters a
    LEFT JOIN actor_earning ae ON a.actor_id = ae.person_id
)

SELECT 
    h.title AS movie_title,
    h.production_year,
    ae.actor_name,
    COALESCE(ae.earnings, 0) AS earnings,
    ROW_NUMBER() OVER (
        PARTITION BY h.title_id 
        ORDER BY COALESCE(ae.earnings, 0) DESC
    ) AS earning_rank
FROM movie_hierarchy h
JOIN assistant_earnings ae ON h.title_id = ae.actor_id
WHERE h.level = 0
  AND (h.title ILIKE '%Fantasy%' OR h.production_year < 2000)
ORDER BY h.production_year DESC, earning_rank ASC
LIMIT 50;
