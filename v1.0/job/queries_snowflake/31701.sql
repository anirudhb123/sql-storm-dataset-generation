
WITH RECURSIVE movie_hierarchy AS (
    SELECT id AS movie_id, title, production_year, episode_of_id
    FROM aka_title
    WHERE production_year >= 2000
    UNION ALL
    SELECT a.id, a.title, a.production_year, a.episode_of_id
    FROM aka_title a
    JOIN movie_hierarchy mh ON a.episode_of_id = mh.movie_id
),
cast_ranks AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
),
keywords_rich_movies AS (
    SELECT
        m.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM movie_keyword m
    JOIN keyword k ON m.keyword_id = k.id
    GROUP BY m.movie_id
),
rich_movie_info AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(kr.keywords, 'No Keywords') AS keywords,
        COUNT(DISTINCT cr.actor_name) AS actor_count,
        CASE 
            WHEN mh.production_year >= 2020 THEN 'Recent'
            ELSE 'Classic'
        END AS period
    FROM movie_hierarchy mh
    LEFT JOIN keywords_rich_movies kr ON mh.movie_id = kr.movie_id
    LEFT JOIN cast_ranks cr ON mh.movie_id = cr.movie_id
    GROUP BY mh.movie_id, mh.title, mh.production_year, kr.keywords
)
SELECT
    rmi.movie_id,
    rmi.title,
    rmi.production_year,
    rmi.keywords,
    rmi.actor_count,
    rmi.period
FROM rich_movie_info rmi
WHERE rmi.actor_count > 5
ORDER BY rmi.production_year DESC, rmi.actor_count DESC;
