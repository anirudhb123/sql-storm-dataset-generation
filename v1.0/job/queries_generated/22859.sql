WITH ranked_movies AS (
    SELECT
        a.title,
        a.production_year,
        COUNT(c.id) AS actor_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.id) DESC) AS rank_within_year
    FROM
        aka_title a
    LEFT JOIN
        cast_info c ON a.id = c.movie_id
    WHERE
        a.production_year IS NOT NULL
    GROUP BY
        a.id, a.title, a.production_year
),
top_movies AS (
    SELECT 
        title,
        production_year
    FROM 
        ranked_movies 
    WHERE 
        rank_within_year <= 5
),
company_hits AS (
    SELECT
        m.title,
        c.name AS company_name,
        COUNT(mc.movie_id) AS num_movies
    FROM
        top_movies m
    JOIN
        movie_companies mc ON m.title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
    LEFT JOIN
        company_name c ON mc.company_id = c.id
    GROUP BY
        m.title, c.name
    HAVING
        COUNT(mc.movie_id) > 1
),
actor_info AS (
    SELECT
        n.name AS actor_name,
        k.keyword AS notable_keyword,
        ROW_NUMBER() OVER (PARTITION BY n.name ORDER BY k.keyword) AS keyword_order
    FROM
        name n
    LEFT JOIN
        movie_keyword mk ON n.imdb_id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
)
SELECT
    tm.title AS top_movie,
    tm.production_year,
    ch.company_name,
    ai.actor_name,
    ai.notable_keyword,
    ai.keyword_order
FROM
    top_movies tm
LEFT JOIN
    company_hits ch ON tm.title = ch.title
LEFT JOIN
    actor_info ai ON tm.title = (SELECT title FROM cast_info ci WHERE ci.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1))
WHERE
    (ai.notable_keyword IS NOT NULL OR ch.company_name IS NOT NULL)
ORDER BY
    tm.production_year DESC,
    tm.title ASC,
    ai.keyword_order DESC NULLS LAST;
