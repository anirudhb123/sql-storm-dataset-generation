WITH RECURSIVE actor_hierarchy AS (
    SELECT
        c.person_id,
        p.name AS actor_name,
        1 AS level
    FROM
        cast_info c
    JOIN
        aka_name p ON c.person_id = p.person_id
    WHERE
        c.movie_id = (SELECT id FROM aka_title WHERE title = 'Inception')
    
    UNION ALL

    SELECT
        c.person_id,
        p.name AS actor_name,
        ah.level + 1
    FROM
        cast_info c
    JOIN
        aka_name p ON c.person_id = p.person_id
    JOIN
        actor_hierarchy ah ON c.movie_id = ah.movie_id
    WHERE
        c.id != ah.person_id
),
movie_keywords AS (
    SELECT
        at.title,
        mk.keyword
    FROM
        aka_title at
    JOIN
        movie_keyword mk ON at.id = mk.movie_id
    WHERE
        at.production_year >= 2000
),
company_movie_info AS (
    SELECT
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    WHERE
        mc.note IS NULL
)
SELECT
    a.actor_name,
    m.production_year,
    mk.keyword,
    cm.company_name,
    cm.company_type,
    ROW_NUMBER() OVER (PARTITION BY a.actor_name ORDER BY m.production_year DESC) AS actor_movie_rank
FROM
    actor_hierarchy a
JOIN
    aka_title m ON a.movie_id = m.id
LEFT JOIN
    movie_keywords mk ON m.title = mk.title
LEFT JOIN
    company_movie_info cm ON m.id = cm.movie_id
WHERE
    a.level <= 3
ORDER BY
    a.actor_name,
    m.production_year DESC
LIMIT 50;
