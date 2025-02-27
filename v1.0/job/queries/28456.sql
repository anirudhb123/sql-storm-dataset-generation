
WITH ranked_titles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM
        aka_title t
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        cast_info c ON t.id = c.movie_id
    JOIN
        aka_name a ON c.person_id = a.person_id
    WHERE
        t.production_year > 2000
    GROUP BY
        t.id, t.title, t.production_year
),
title_with_keywords AS (
    SELECT
        r.title_id,
        r.title,
        r.production_year,
        r.actor_count,
        r.actor_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        ranked_titles r
    LEFT JOIN
        movie_keyword mk ON r.title_id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        r.title_id, r.title, r.production_year, r.actor_count, r.actor_names
),
final_benchmark AS (
    SELECT
        twk.title_id,
        twk.title,
        twk.production_year,
        twk.actor_count,
        twk.actor_names,
        twk.keywords,
        CASE 
            WHEN twk.actor_count > 5 THEN 'High'
            WHEN twk.actor_count BETWEEN 3 AND 5 THEN 'Medium'
            ELSE 'Low'
        END AS actor_count_category
    FROM
        title_with_keywords twk
    WHERE
        twk.keywords IS NOT NULL
)

SELECT
    fb.title_id,
    fb.title,
    fb.production_year,
    fb.actor_count,
    fb.actor_names,
    fb.keywords,
    fb.actor_count_category
FROM
    final_benchmark fb
ORDER BY
    fb.actor_count DESC, fb.production_year DESC;
