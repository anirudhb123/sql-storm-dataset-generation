
WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM aka_title mt
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM aka_title mt
    JOIN movie_link ml ON mt.id = ml.linked_movie_id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
actor_performance AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ca.movie_id) AS total_movies,
        SUM(CASE WHEN ma.production_year = 2023 THEN 1 ELSE 0 END) AS movies_in_2023,
        ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY COUNT(DISTINCT ca.movie_id) DESC) AS actor_rank
    FROM aka_name ak
    LEFT JOIN cast_info ca ON ak.person_id = ca.person_id
    LEFT JOIN aka_title ma ON ca.movie_id = ma.id
    LEFT JOIN movie_info mi ON ma.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'box office')
    WHERE ak.name IS NOT NULL
      AND (mi.info LIKE '%billion%' OR mi.info LIKE '%million%')
      AND ma.production_year IS NOT NULL
    GROUP BY ak.id, ak.name
),
actor_summary AS (
    SELECT 
        actor_name, 
        total_movies,
        movies_in_2023,
        actor_rank,
        CASE
            WHEN total_movies >= 10 THEN 'Veteran'
            WHEN total_movies BETWEEN 5 AND 9 THEN 'Emerging'
            ELSE 'Novice'
        END AS experience_level
    FROM actor_performance
    WHERE movies_in_2023 > 0
),
keyword_summary AS (
    SELECT 
        keyword.keyword AS keyword_text,
        COUNT(DISTINCT mk.movie_id) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword ON mk.keyword_id = keyword.id
    GROUP BY keyword.keyword
    HAVING COUNT(DISTINCT mk.movie_id) > 5
),
final_report AS (
    SELECT 
        asum.actor_name,
        asum.total_movies,
        asum.movies_in_2023,
        asum.experience_level,
        ksum.keyword_text,
        ksum.keyword_count
    FROM actor_summary asum
    LEFT JOIN keyword_summary ksum ON asum.total_movies > ksum.keyword_count
    ORDER BY asum.actor_rank, ksum.keyword_count DESC
)
SELECT 
    fr.actor_name,
    fr.total_movies,
    fr.movies_in_2023,
    fr.experience_level,
    COALESCE(fr.keyword_text, 'None') AS keyword_text,
    COALESCE(fr.keyword_count, 0) AS keyword_count
FROM final_report fr
WHERE fr.movies_in_2023 > 0
  AND (fr.keyword_count IS NULL OR fr.keyword_count > 2)
ORDER BY fr.movies_in_2023 DESC, fr.total_movies DESC;
