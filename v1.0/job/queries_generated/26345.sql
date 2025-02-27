WITH movie_details AS (
    SELECT
        t.title,
        t.production_year,
        t.kind_id,
        k.keyword,
        a.name AS actor_name,
        p.gender,
        c.name AS company_name,
        mi.info AS movie_info
    FROM
        title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN
        company_name c ON t.id IN (SELECT movie_id FROM movie_companies WHERE company_id = c.id)
    LEFT JOIN
        movie_info mi ON t.id = mi.movie_id
    WHERE
        t.production_year >= 2000
),
gender_count AS (
    SELECT
        gender,
        COUNT(*) AS count
    FROM
        movie_details
    GROUP BY
        gender
),
keyword_count AS (
    SELECT
        keyword,
        COUNT(*) AS count
    FROM
        movie_details
    GROUP BY
        keyword
)
SELECT
    md.title,
    md.production_year,
    g.gender,
    g.count AS gender_count,
    k.keyword,
    k.count AS keyword_count,
    md.company_name,
    md.movie_info
FROM
    movie_details md
JOIN
    gender_count g ON md.gender = g.gender
JOIN
    keyword_count k ON md.keyword = k.keyword
ORDER BY
    md.production_year DESC, g.count DESC, k.count DESC;
