WITH ranked_movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank_by_cast_size
    FROM
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY
        t.id, t.title, t.production_year
),

actor_movie_counts AS (
    SELECT
        ak.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM
        aka_name ak
    JOIN
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY
        ak.person_id
),

complex_join AS (
    SELECT
        akn.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT m.id) AS production_companies,
        COALESCE(kt.keyword, 'No Keyword') AS keyword_used
    FROM
        aka_name akn
    LEFT JOIN
        cast_info ci ON ci.person_id = akn.person_id
    LEFT JOIN
        aka_title t ON t.id = ci.movie_id
    LEFT JOIN
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN
        company_name cn ON cn.id = mc.company_id
    LEFT JOIN
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN
        keyword kt ON kt.id = mk.keyword_id
    WHERE
        akn.name IS NOT NULL
        AND (t.production_year IS NOT NULL OR t.production_year IS NULL)
    GROUP BY
        akn.name, t.title, t.production_year, kt.keyword
),

final_selection AS (
    SELECT
        c.actor_name,
        c.movie_title,
        c.production_year,
        c.production_companies,
        ac.movie_count,
        RANK() OVER (PARTITION BY c.production_year ORDER BY c.production_companies DESC) AS rank
    FROM
        complex_join c
    JOIN
        actor_movie_counts ac ON ac.person_id = (
            SELECT person_id FROM aka_name WHERE name = c.actor_name LIMIT 1
        )
)

SELECT
    *
FROM
    final_selection
WHERE
    rank <= 5
ORDER BY
    production_year DESC, production_companies DESC;
