WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM aka_title mt
    WHERE mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id, 
        at.title AS movie_title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM movie_link ml
    JOIN aka_title at ON ml.linked_movie_id = at.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE mh.level < 3
),
actor_movie_counts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM cast_info ci
    JOIN movie_hierarchy mh ON ci.movie_id = mh.movie_id
    GROUP BY ci.person_id
),
ranked_actors AS (
    SELECT 
        na.name AS actor_name,
        ac.movie_count,
        RANK() OVER (ORDER BY ac.movie_count DESC) AS actor_rank
    FROM actor_movie_counts ac
    JOIN aka_name na ON ac.person_id = na.person_id
    WHERE na.name IS NOT NULL AND ac.movie_count > 0
),
keyword_movie_counts AS (
    SELECT 
        mk.keyword AS keyword_name,
        COUNT(DISTINCT mk.movie_id) AS keyword_count
    FROM movie_keyword mk
    JOIN movie_hierarchy mh ON mk.movie_id = mh.movie_id
    GROUP BY mk.keyword
),
top_keywords AS (
    SELECT 
        keyword_name,
        keyword_count,
        RANK() OVER (ORDER BY keyword_count DESC) AS keyword_rank
    FROM keyword_movie_counts
)
SELECT 
    ra.actor_name,
    ra.movie_count AS total_movies,
    tk.keyword_name,
    tk.keyword_count,
    tk.keyword_rank
FROM ranked_actors ra
FULL OUTER JOIN top_keywords tk ON ra.actor_rank = tk.keyword_rank
WHERE 
    (ra.total_movies IS NOT NULL OR tk.keyword_count IS NOT NULL)
ORDER BY 
    COALESCE(ra.actor_rank, 999) ASC,
    COALESCE(tk.keyword_rank, 999) ASC;
