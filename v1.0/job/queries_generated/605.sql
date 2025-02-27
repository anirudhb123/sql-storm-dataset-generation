WITH MovieRoles AS (
    SELECT
        a.name AS actor_name,
        t.title AS movie_title,
        c.nr_order AS cast_order,
        r.role AS role_name
    FROM
        cast_info c
    INNER JOIN aka_name a ON c.person_id = a.person_id
    INNER JOIN title t ON c.movie_id = t.id
    INNER JOIN role_type r ON c.role_id = r.id
    WHERE
        t.production_year >= 2000
        AND a.name IS NOT NULL
),
RankedMovies AS (
    SELECT
        actor_name,
        movie_title,
        cast_order,
        role_name,
        ROW_NUMBER() OVER (PARTITION BY actor_name ORDER BY cast_order) AS rn
    FROM
        MovieRoles
)
SELECT
    r.actor_name,
    STRING_AGG(r.movie_title, ', ') AS movies,
    COUNT(DISTINCT r.movie_title) AS movie_count,
    MAX(r.cast_order) AS max_order,
    CASE
        WHEN COUNT(DISTINCT r.movie_title) > 5 THEN 'Prolific Actor'
        ELSE 'Emerging Talent'
    END AS actor_status
FROM
    RankedMovies r
GROUP BY
    r.actor_name
HAVING
    MAX(r.cast_order) > 2
ORDER BY
    movie_count DESC;

SELECT
    m.title,
    km.keyword,
    COUNT(DISTINCT c.person_id) AS actor_count
FROM
    aka_title m
LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN keyword km ON mk.keyword_id = km.id
LEFT JOIN cast_info c ON m.id = c.movie_id
WHERE
    m.production_year > 2010
    AND km.keyword IS NOT NULL
GROUP BY
    m.title, km.keyword
ORDER BY
    actor_count DESC, m.title;

SELECT
    c.id AS company_id,
    cn.name AS company_name,
    COUNT(DISTINCT mc.movie_id) AS movies_produced,
    AVG(m.production_year) AS avg_production_year
FROM
    company_name cn
LEFT JOIN movie_companies mc ON cn.id = mc.company_id
LEFT JOIN aka_title m ON mc.movie_id = m.id
WHERE
    cn.country_code IS NOT NULL
GROUP BY
    c.id, cn.name
HAVING
    COUNT(DISTINCT mc.movie_id) > 0
ORDER BY
    avg_production_year DESC;
