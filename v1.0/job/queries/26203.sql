WITH ranked_titles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (
            PARTITION BY t.production_year
            ORDER BY t.title
        ) AS title_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
cast_members AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        role_type r ON c.role_id = r.id
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        k.keyword
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
),
company_movies AS (
    SELECT
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
)
SELECT
    rt.title,
    rt.production_year,
    cm.actor_name,
    cm.role_name,
    mk.keyword,
    cm.movie_id,
    cm.movie_id AS linked_movie_id
FROM
    ranked_titles rt
JOIN
    cast_members cm ON rt.title_id = cm.movie_id
LEFT JOIN
    movie_keywords mk ON cm.movie_id = mk.movie_id
JOIN
    company_movies com ON cm.movie_id = com.movie_id
WHERE
    rt.title_rank <= 5
    AND mk.keyword IS NOT NULL
ORDER BY
    rt.production_year DESC,
    rt.title ASC,
    cm.actor_name;