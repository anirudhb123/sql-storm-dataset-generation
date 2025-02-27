WITH RECURSIVE cast_hierarchy AS (
    SELECT ci.person_id, 
           t.title AS movie_title,
           ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY t.production_year DESC) AS rn
    FROM cast_info ci
    JOIN aka_title t ON ci.movie_id = t.id
    WHERE t.production_year >= 2000

    UNION ALL

    SELECT ci.person_id,
           t.title AS movie_title,
           ch.rn + 1 AS rn
    FROM cast_info ci
    JOIN aka_title t ON ci.movie_id = t.id
    JOIN cast_hierarchy ch ON ci.person_id = ch.person_id
    WHERE t.production_year < 2000 AND ch.rn < 5
),

movie_details AS (
    SELECT m.id AS movie_id,
           m.title,
           m.production_year,
           ARRAY_AGG(DISTINCT k.keyword) AS keywords,
           COUNT(DISTINCT mc.company_id) AS production_company_count
    FROM aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc ON m.id = mc.movie_id
    GROUP BY m.id, m.title, m.production_year
)

SELECT ch.person_id,
       n.name AS actor_name,
       md.movie_id,
       md.title,
       md.production_year,
       md.keywords,
       md.production_company_count
FROM cast_hierarchy ch
JOIN name n ON ch.person_id = n.id
JOIN movie_details md ON md.movie_id = ch.movie_title
WHERE n.gender = 'M'
  AND md.production_year > 2010
  AND md.production_company_count > 1
ORDER BY md.production_year DESC, ch.person_id;
This query does the following:
1. Uses a recursive CTE to build a hierarchy of actors based on their roles in films from the last 20+ years and tracks the number of appearances.
2. Aggregates movie details, including total keywords and production companies, utilizing grouping and array aggregation.
3. Joins the results from both CTEs to get a detailed view of male actors who worked in movies produced after 2010, with additional filters for production company counts.
4. Orders the final result set by the year of production and actor ID to aid in benchmarking performance on complex joins and aggregations.
