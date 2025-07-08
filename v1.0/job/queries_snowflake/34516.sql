
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        COALESCE(mt.season_nr, 0) AS season_nr, 
        COALESCE(mt.episode_nr, 0) AS episode_nr,
        1 AS level
    FROM aka_title mt
    WHERE mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        COALESCE(mt.season_nr, 0) AS season_nr, 
        COALESCE(mt.episode_nr, 0) AS episode_nr,
        mh.level + 1
    FROM aka_title mt
    JOIN movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
),
top_movies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM aka_title a
    LEFT JOIN cast_info ci ON a.id = ci.movie_id
    WHERE a.production_year IS NOT NULL
    GROUP BY a.id, a.title, a.production_year
),
movies_with_keywords AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM aka_title a
    LEFT JOIN movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY a.id, a.title
),
final_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.season_nr,
        mh.episode_nr,
        COALESCE(tm.actor_count, 0) AS total_actors,
        COALESCE(mk.keywords, 'No keywords') AS keywords
    FROM movie_hierarchy mh
    LEFT JOIN top_movies tm ON mh.movie_id = tm.movie_id
    LEFT JOIN movies_with_keywords mk ON mh.movie_id = mk.movie_id
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.season_nr,
    f.episode_nr,
    f.total_actors,
    f.keywords,
    CASE 
        WHEN f.total_actors > 10 THEN 'Highly Casted'
        WHEN f.total_actors BETWEEN 5 AND 10 THEN 'Moderately Casted'
        ELSE 'Low Casted'
    END AS cast_category
FROM final_movies f
WHERE f.production_year > 2000
ORDER BY f.production_year DESC, f.total_actors DESC;
