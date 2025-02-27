WITH movie_years AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        k.keyword
    FROM
        aka_title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        t.production_year BETWEEN 2000 AND 2023
),
cast_details AS (
    SELECT
        ci.movie_id,
        a.name AS actor_name,
        ROUND(AVG(pi.cast_order), 2) AS avg_order
    FROM
        cast_info ci
    JOIN
        aka_name a ON ci.person_id = a.person_id
    JOIN
        (SELECT
            movie_id,
            ROW_NUMBER() OVER (PARTITION BY movie_id ORDER BY nr_order) AS cast_order
        FROM
            cast_info
        ) pi ON ci.movie_id = pi.movie_id
    GROUP BY
        ci.movie_id, a.name
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
    WHERE
        cn.country_code = 'USA'
)
SELECT
    m.movie_id,
    m.title,
    m.production_year,
    STRING_AGG(DISTINCT c.actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT co.company_name || ' (' || co.company_type || ')', ', ') AS companies,
    STRING_AGG(DISTINCT m.keyword, ', ') AS keywords,
    COUNT(DISTINCT c.actor_name) AS actor_count,
    AVG(c.avg_order) AS avg_cast_order
FROM
    movie_years m
LEFT JOIN
    cast_details c ON m.movie_id = c.movie_id
LEFT JOIN
    company_details co ON m.movie_id = co.movie_id
GROUP BY
    m.movie_id, m.title, m.production_year
ORDER BY
    m.production_year DESC, actor_count DESC;
