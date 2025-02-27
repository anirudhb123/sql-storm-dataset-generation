
WITH ranked_titles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_titles
    FROM
        title t
    WHERE
        t.production_year IS NOT NULL
),
extended_cast_info AS (
    SELECT
        ci.movie_id,
        ci.person_id,
        ci.nr_order,
        COALESCE(aka.name, char.name, 'Unknown') AS actor_name,
        ci.note AS role_note
    FROM
        cast_info ci
    LEFT JOIN aka_name aka ON aka.person_id = ci.person_id
    LEFT JOIN char_name char ON char.imdb_id = ci.person_id
),
movies_with_keyword AS (
    SELECT
        mt.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN aka_title mt ON mt.id = mk.movie_id
    GROUP BY mt.movie_id
),
summary AS (
    SELECT
        title.title,
        title.production_year,
        COALESCE(ec.actor_name, 'No Cast') AS cast_member,
        rk.title_rank,
        mk.keywords,
        rk.total_titles
    FROM
        title
    LEFT JOIN extended_cast_info ec ON ec.movie_id = title.id
    LEFT JOIN ranked_titles rk ON rk.title_id = title.id
    LEFT JOIN movies_with_keyword mk ON mk.movie_id = title.id
    WHERE
        title.production_year BETWEEN 2000 AND 2020
        AND (ec.role_note IS NULL OR ec.role_note NOT LIKE '%Cameo%')
)
SELECT
    s.title,
    s.production_year,
    s.cast_member,
    s.title_rank,
    s.keywords,
    CASE
        WHEN s.title_rank = 1 THEN 'Top Title'
        WHEN s.title_rank <= (s.total_titles / 10) THEN 'Top 10%'
        ELSE 'Other'
    END AS rank_category
FROM
    summary s
LEFT JOIN (
    SELECT
        production_year,
        COUNT(*) AS total_titles
    FROM
        title
    WHERE
        production_year IS NOT NULL
    GROUP BY production_year
) totals ON totals.production_year = s.production_year
ORDER BY s.production_year, s.title_rank;
