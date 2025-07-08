
WITH ranked_titles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS title_rank
    FROM
        aka_title t
),

actor_movie_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM
        cast_info ci
    JOIN
        aka_name an ON ci.person_id = an.person_id
    GROUP BY
        ci.movie_id
),

keyword_analysis AS (
    SELECT
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)

SELECT
    t.title,
    t.production_year,
    rt.title_rank,
    amc.actor_count,
    ka.keywords
FROM
    ranked_titles rt
JOIN
    aka_title t ON rt.title_id = t.id
LEFT JOIN
    actor_movie_counts amc ON t.id = amc.movie_id
LEFT JOIN
    keyword_analysis ka ON t.id = ka.movie_id
WHERE
    rt.title_rank <= 5
GROUP BY
    t.title,
    t.production_year,
    rt.title_rank,
    amc.actor_count,
    ka.keywords
ORDER BY
    t.production_year DESC, rt.title_rank;
