
WITH movie_details AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names
    FROM
        title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info ci ON cc.subject_id = ci.id
    JOIN
        aka_name an ON ci.person_id = an.person_id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id, t.title, t.production_year
),
person_details AS (
    SELECT
        p.id AS person_id,
        p.name,
        pi.info AS biography
    FROM
        name p
    LEFT JOIN
        person_info pi ON p.id = pi.person_id
    WHERE
        p.gender = 'F'
)
SELECT
    md.title,
    md.production_year,
    md.keywords,
    md.company_names,
    pd.name AS actor_name,
    pd.biography
FROM
    movie_details md
JOIN
    person_details pd ON md.actor_names LIKE '%' || pd.name || '%'
ORDER BY
    md.production_year DESC, md.title ASC
LIMIT 100;
