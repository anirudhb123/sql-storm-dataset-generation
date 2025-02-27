WITH movie_details AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.kind, ', ') AS company_kinds
    FROM
        aka_title t
        LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
        LEFT JOIN keyword k ON mk.keyword_id = k.id
        LEFT JOIN movie_companies mc ON t.id = mc.movie_id
        LEFT JOIN company_type c ON mc.company_type_id = c.id
    WHERE
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY
        t.id, t.title, t.production_year
),
actor_details AS (
    SELECT
        p.id AS person_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM
        aka_name a
        JOIN cast_info ci ON a.person_id = ci.person_id
        JOIN title t ON ci.movie_id = t.id
        JOIN movie_info mi ON t.id = mi.movie_id
    WHERE
        mi.info_type_id = 1 -- assuming this represents primary info type
        AND t.production_year BETWEEN 2000 AND 2020
    GROUP BY
        a.id, a.name
)
SELECT
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.keywords,
    md.company_kinds,
    ad.actor_name,
    ad.movie_count
FROM
    movie_details md
    LEFT JOIN actor_details ad ON md.movie_id IN (
        SELECT movie_id FROM cast_info WHERE person_id IN (SELECT person_id FROM aka_name WHERE name LIKE '%Smith%')
    )
ORDER BY
    md.production_year DESC, md.movie_title;
