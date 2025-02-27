WITH person_movies AS (
    SELECT
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM
        aka_name a
        JOIN cast_info ci ON a.person_id = ci.person_id
        JOIN aka_title t ON ci.movie_id = t.movie_id
        LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
        LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY
        a.name, t.title, t.production_year
),
movie_info_summary AS (
    SELECT
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actors_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors_list
    FROM
        aka_title t
        JOIN cast_info ci ON t.movie_id = ci.movie_id
        JOIN aka_name a ON ci.person_id = a.person_id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.title, t.production_year
),
keyword_summary AS (
    SELECT
        k.keyword,
        COUNT(mk.movie_id) AS movie_count
    FROM
        keyword k
        JOIN movie_keyword mk ON k.id = mk.keyword_id
    GROUP BY
        k.keyword
    HAVING
        COUNT(mk.movie_id) > 10
)
SELECT
    pm.actor_name,
    pm.movie_title,
    pm.production_year,
    COALESCE(mis.actors_count, 0) AS total_actors,
    mis.actors_list,
    ARRAY_AGG(DISTINCT ks.keyword) AS keywords,
    ks.movie_count AS keyword_movie_count
FROM
    person_movies pm
    LEFT JOIN movie_info_summary mis ON pm.movie_title = mis.title AND pm.production_year = mis.production_year
    LEFT JOIN keyword_summary ks ON ks.keyword = ANY(pm.keywords)
GROUP BY
    pm.actor_name, pm.movie_title, pm.production_year, mis.actors_count, mis.actors_list, ks.keyword_movie_count
ORDER BY
    pm.actor_name, pm.movie_title;
