WITH RECURSIVE actor_hierarchy AS (
    SELECT ci.person_id, ci.movie_id, 1 AS depth
    FROM cast_info ci
    WHERE ci.role_id IS NOT NULL
    UNION ALL
    SELECT ci.person_id, ci.movie_id, ah.depth + 1
    FROM cast_info ci
    JOIN actor_hierarchy ah ON ci.movie_id = ah.movie_id
    WHERE ci.person_id <> ah.person_id
),

movie_details AS (
    SELECT 
          mt.production_year,
          mt.title,
          mt.kind_id,
          COUNT(DISTINCT ci.person_id) AS total_actors,
          STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM aka_title mt
    LEFT JOIN cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
    WHERE mt.production_year IS NOT NULL
      AND mt.kind_id IN (
          SELECT id FROM kind_type WHERE kind LIKE 'F%'
      )
    GROUP BY mt.id, mt.production_year, mt.title, mt.kind_id
    HAVING COUNT(DISTINCT ak.id) > 1
),

ranked_movies AS (
    SELECT 
        md.production_year,
        md.title,
        md.total_actors,
        RANK() OVER (PARTITION BY md.production_year ORDER BY md.total_actors DESC) AS rank
    FROM movie_details md
),

movie_info AS (
    SELECT 
        mt.title,
        COUNT(DISTINCT mc.company_id) AS production_company_count
    FROM aka_title mt
    LEFT JOIN movie_companies mc ON mt.id = mc.movie_id
    GROUP BY mt.title
)

SELECT 
    rm.production_year,
    rm.title,
    rm.total_actors,
    rm.rank,
    mi.production_company_count,
    CASE 
        WHEN rm.rank <= 5 THEN 'Top 5 Movies'
        ELSE 'Below Top 5'
    END AS ranking_category,
    COALESCE(GREATEST(rm.total_actors, mi.production_company_count), 0) AS max_participants
FROM ranked_movies rm
LEFT JOIN movie_info mi ON rm.title = mi.title
WHERE rm.rank <= 10
  AND rm.production_year >= 2000
ORDER BY rm.production_year DESC, rm.total_actors DESC;
