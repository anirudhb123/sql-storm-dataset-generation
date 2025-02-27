WITH movie_details AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        c.name AS company_name,
        r.role AS person_role,
        a.name AS actor_name,
        COUNT(mk.keyword_id) AS keyword_count
    FROM
        title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN
        role_type r ON ci.role_id = r.id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    WHERE
        t.production_year > 2000
    GROUP BY
        t.id, t.title, t.production_year, k.keyword, c.name, r.role, a.name
),
movie_rank AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY title_id ORDER BY keyword_count DESC) AS rank
    FROM
        movie_details
)

SELECT
    title_id,
    title,
    production_year,
    keyword,
    company_name,
    person_role,
    actor_name,
    keyword_count,
    rank
FROM
    movie_rank
WHERE
    rank <= 3
ORDER BY
    production_year DESC, title;

