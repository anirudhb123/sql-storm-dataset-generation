WITH title_keywords AS (
    SELECT
        t.id AS title_id,
        t.title,
        k.keyword,
        COUNT(mk.keyword_id) AS keyword_count
    FROM
        title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        t.id, t.title, k.keyword
),
ranked_titles AS (
    SELECT
        tk.title_id,
        tk.title,
        tk.keyword,
        tk.keyword_count,
        ROW_NUMBER() OVER (PARTITION BY tk.title_id ORDER BY tk.keyword_count DESC) AS rank
    FROM
        title_keywords tk
)

SELECT
    t.title AS movie_title,
    a.name AS actor_name,
    a.imdb_index AS actor_imdb_index,
    c.kind AS role_type,
    r.role AS role,
    t.production_year,
    rank.keyword,
    rank.keyword_count
FROM
    ranked_titles rank
JOIN
    title t ON rank.title_id = t.id
JOIN
    cast_info ci ON t.id = ci.movie_id
JOIN
    aka_name a ON ci.person_id = a.person_id
JOIN
    role_type r ON ci.role_id = r.id
JOIN
    comp_cast_type c ON ci.person_role_id = c.id
WHERE
    rank.rank = 1
    AND t.production_year >= 2000
ORDER BY
    t.production_year DESC,
    rank.keyword_count DESC;
