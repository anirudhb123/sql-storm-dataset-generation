WITH ranked_titles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(mk.id) AS keyword_count
    FROM
        title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY
        t.id
), most_frequent_actor AS (
    SELECT
        ai.name,
        COUNT(ci.id) AS movie_count
    FROM
        aka_name ai
    JOIN
        cast_info ci ON ai.person_id = ci.person_id
    GROUP BY
        ai.name
    ORDER BY
        movie_count DESC
    LIMIT 1
), title_with_actors AS (
    SELECT
        t.title,
        ai.name AS actor_name,
        t.production_year
    FROM
        title t
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        aka_name ai ON mc.company_id = ai.person_id
    WHERE
        t.production_year BETWEEN 2000 AND 2023
), movie_info_per_title AS (
    SELECT
        t.title,
        mi.info AS movie_info
    FROM
        title t
    LEFT JOIN
        movie_info mi ON t.id = mi.movie_id
    WHERE
        mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Award%')
)
SELECT
    tt.title,
    tt.production_year,
    tt.keyword_count,
    fa.name AS frequent_actor,
    GROUP_CONCAT(DISTINCT ti.movie_info) AS awards_info
FROM
    ranked_titles tt
JOIN
    most_frequent_actor fa ON 1=1
LEFT JOIN
    movie_info_per_title ti ON tt.title = ti.title
GROUP BY
    tt.title, tt.production_year, fa.name
ORDER BY
    tt.keyword_count DESC
LIMIT 10;
