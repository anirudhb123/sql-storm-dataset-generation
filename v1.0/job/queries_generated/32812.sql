WITH RECURSIVE cast_hierarchy AS (
    SELECT ci.movie_id,
           ci.person_id,
           1 AS level
    FROM cast_info ci
    WHERE ci.role_id IS NOT NULL
    
    UNION ALL
    
    SELECT ci.movie_id,
           ci.person_id,
           ch.level + 1
    FROM cast_info ci
    JOIN cast_hierarchy ch ON ci.movie_id = ch.movie_id
    WHERE ci.person_id <> ch.person_id
),
movie_ratings AS (
    SELECT title.id AS movie_id,
           title.title,
           AVG(CASE WHEN mi.info_type_id = it.id THEN mi.info::numeric END) AS avg_rating
    FROM title
    JOIN movie_info mi ON title.id = mi.movie_id
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
    GROUP BY title.id, title.title
),
keyword_stats AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT k.keyword) AS keyword_count,
           STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
movie_summary AS (
    SELECT t.id AS movie_id,
           t.title,
           t.production_year,
           COALESCE(mr.avg_rating, 0) AS avg_rating,
           COALESCE(ks.keyword_count, 0) AS keyword_count,
           ks.keywords
    FROM title t
    LEFT JOIN movie_ratings mr ON t.id = mr.movie_id
    LEFT JOIN keyword_stats ks ON t.id = ks.movie_id
),
cast_info_summary AS (
    SELECT ch.movie_id,
           COUNT(DISTINCT ch.person_id) AS cast_count,
           MAX(ch.level) AS max_level
    FROM cast_hierarchy ch
    GROUP BY ch.movie_id
)
SELECT ms.movie_id,
       ms.title,
       ms.production_year,
       ms.avg_rating,
       ms.keyword_count,
       ms.keywords,
       COALESCE(ci.cast_count, 0) AS cast_count,
       COALESCE(ci.max_level, 0) AS max_level,
       CASE 
           WHEN ms.avg_rating IS NULL THEN 'Rating not available'
           WHEN ms.avg_rating > 8 THEN 'High'
           WHEN ms.avg_rating >= 5 THEN 'Medium'
           ELSE 'Low'
       END AS rating_category
FROM movie_summary ms
LEFT JOIN cast_info_summary ci ON ms.movie_id = ci.movie_id
WHERE ms.production_year >= 2000
ORDER BY ms.avg_rating DESC, ms.title;
