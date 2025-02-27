WITH RECURSIVE ActorHierarchies AS (
    SELECT
        c.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        1 AS hierarchy_level
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        aka_title t ON c.movie_id = t.movie_id
    WHERE
        t.production_year >= 2000

    UNION ALL

    SELECT
        c.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        ah.hierarchy_level + 1
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        aka_title t ON c.movie_id = t.movie_id
    JOIN
        ActorHierarchies ah ON c.movie_id = ah.person_id
    WHERE
        t.production_year >= 2000
)

SELECT
    ah.actor_name,
    COUNT(DISTINCT ah.movie_title) AS movie_count,
    STRING_AGG(DISTINCT ah.movie_title, ', ') AS movie_titles,
    MAX(ah.hierarchy_level) AS max_hierarchy_level
FROM
    ActorHierarchies ah
GROUP BY
    ah.actor_name
HAVING
    COUNT(DISTINCT ah.movie_title) > 5
ORDER BY
    movie_count DESC;

-- Performance Benchmarking Query
SELECT
    m.title AS movie_title,
    c.kind AS company_type,
    COUNT(DISTINCT cm.company_id) AS company_count,
    AVG(mi.info) AS average_info_length,
    MAX(CASE WHEN mi.info IS NOT NULL THEN LENGTH(mi.info) ELSE 0 END) AS longest_info_length,
    SUM(
        CASE
            WHEN c.kind IS NOT NULL THEN 1
            ELSE 0
        END
    ) AS non_null_company_count
FROM
    aka_title m
LEFT JOIN
    movie_companies mc ON m.id = mc.movie_id
LEFT JOIN
    company_name cn ON mc.company_id = cn.id
LEFT JOIN
    company_type c ON mc.company_type_id = c.id
LEFT JOIN
    movie_info mi ON m.id = mi.movie_id
WHERE
    m.production_year BETWEEN 2000 AND 2023
GROUP BY
    m.title, c.kind
HAVING
    AVG(LENGTH(mi.info)) > 20
ORDER BY
    company_count DESC
LIMIT 10;

-- Include a window function to show rank of movies based on company count
SELECT
    title,
    company_count,
    RANK() OVER (ORDER BY company_count DESC) AS rank
FROM (
    SELECT
        m.title,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM
        aka_title m
    LEFT JOIN
        movie_companies mc ON m.id = mc.movie_id
    GROUP BY
        m.title
) AS company_counts
ORDER BY
    company_count DESC
LIMIT 5;
