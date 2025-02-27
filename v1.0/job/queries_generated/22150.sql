WITH ranked_movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_in_year,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies_in_year
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
cast_movies AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        a.person_id,
        r.role AS role_name,
        COALESCE(m.note, 'No Note') AS movie_note
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN
        role_type r ON c.role_id = r.id
    LEFT JOIN
        movie_info m ON c.movie_id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Note' LIMIT 1)
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.rank_in_year,
    rm.total_movies_in_year,
    cm.actor_name,
    COALESCE(cm.movie_note, 'No Details') AS movie_note,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COUNT(cm.person_id) OVER (PARTITION BY rm.movie_id) AS actor_count,
    CASE
        WHEN COUNT(cm.person_id) OVER (PARTITION BY rm.movie_id) > 5 THEN 'Star Ensemble'
        ELSE 'Small Cast'
    END AS cast_size,
    (SELECT AVG(CAST(mi.info AS NUMERIC)) FROM movie_info mi WHERE mi.movie_id = rm.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE 'Rating%')) AS average_rating
FROM
    ranked_movies rm
LEFT JOIN
    cast_movies cm ON rm.movie_id = cm.movie_id
LEFT JOIN
    movie_keywords mk ON rm.movie_id = mk.movie_id
WHERE
    rm.production_year > 2000
    AND (rm.rank_in_year IS NULL OR rm.rank_in_year BETWEEN 1 AND 10)
ORDER BY
    rm.production_year DESC,
    rm.rank_in_year ASC,
    CAST(rm.title AS VARCHAR(255)) ASC;
