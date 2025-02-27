WITH movie_details AS (
    SELECT
        t.title,
        t.production_year,
        a.name AS actor_name,
        c.kind AS cast_type
    FROM
        aka_title t
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info ci ON cc.subject_id = ci.id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    JOIN
        role_type r ON ci.role_id = r.id
    JOIN
        comp_cast_type c ON r.id = c.id
    WHERE
        t.production_year >= 2000
),
keyword_count AS (
    SELECT
        movie_id,
        COUNT(keyword_id) AS total_keywords
    FROM
        movie_keyword
    GROUP BY
        movie_id
),
company_details AS (
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
    md.title,
    md.production_year,
    md.actor_name,
    md.cast_type,
    kc.total_keywords,
    cd.company_name,
    cd.company_type
FROM
    movie_details md
LEFT JOIN
    keyword_count kc ON md.title = kc.movie_id
LEFT JOIN
    company_details cd ON md.title = cd.movie_id
ORDER BY
    md.production_year DESC, 
    md.title;
