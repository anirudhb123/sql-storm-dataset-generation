WITH movie_summary AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS alternative_names,
        ARRAY_AGG(DISTINCT kw.keyword) AS keywords,
        COUNT(DISTINCT mc.company_id) AS production_companies
    FROM
        aka_title t
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        aka_name ak ON ak.person_id IN (
            SELECT DISTINCT ci.person_id
            FROM cast_info ci
            WHERE ci.movie_id = t.id
        )
    GROUP BY
        t.id,
        t.title,
        t.production_year
),
character_cast AS (
    SELECT
        t.id AS movie_id,
        c.person_id,
        c.person_role_id,
        r.role AS person_role
    FROM
        cast_info c
    JOIN
        title t ON c.movie_id = t.id
    JOIN
        role_type r ON c.role_id = r.id
    WHERE
        r.role IS NOT NULL
)
SELECT
    ms.movie_id,
    ms.movie_title,
    ms.production_year,
    ms.alternative_names,
    ms.keywords,
    ms.production_companies,
    COUNT(DISTINCT cc.person_id) AS cast_count,
    STRING_AGG(DISTINCT cc.person_role || ': ' || (SELECT n.name FROM name n WHERE n.id = cc.person_id), '; ') AS cast_roles
FROM
    movie_summary ms
LEFT JOIN
    character_cast cc ON ms.movie_id = cc.movie_id
GROUP BY
    ms.movie_id,
    ms.movie_title,
    ms.production_year,
    ms.alternative_names,
    ms.keywords,
    ms.production_companies
ORDER BY
    ms.production_year DESC, ms.movie_title;
