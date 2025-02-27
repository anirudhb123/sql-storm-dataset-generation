WITH RECURSIVE cast_hierarchy AS (
    SELECT
        c.id AS cast_id,
        c.person_id,
        c.movie_id,
        c.nr_order,
        1 AS level
    FROM
        cast_info c
    WHERE
        c.nr_order = 1

    UNION ALL

    SELECT
        c.id AS cast_id,
        c.person_id,
        c.movie_id,
        c.nr_order,
        ch.level + 1
    FROM
        cast_info c
    INNER JOIN cast_hierarchy ch ON c.movie_id = ch.movie_id
    WHERE
        c.nr_order = ch.nr_order + 1
),
ranked_movies AS (
    SELECT
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rn
    FROM
        aka_title t
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY
        t.title, t.production_year
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    t.title,
    t.production_year,
    mk.keywords,
    rw.company_count,
    CASE 
        WHEN rw.company_count > 5 THEN 'Large Casting'
        WHEN rw.company_count BETWEEN 3 AND 5 THEN 'Medium Casting'
        ELSE 'Small Casting'
    END AS casting_size,
    ch.level,
    a.name AS actor_name
FROM
    ranked_movies rw
LEFT JOIN
    aka_title t ON rw.title = t.title AND rw.production_year = t.production_year
LEFT JOIN
    movie_keywords mk ON t.id = mk.movie_id
LEFT JOIN
    cast_info c ON t.id = c.movie_id
LEFT JOIN
    aka_name a ON c.person_id = a.person_id
LEFT JOIN
    cast_hierarchy ch ON c.id = ch.cast_id
WHERE
    t.production_year BETWEEN 2000 AND 2023
    AND a.name IS NOT NULL
ORDER BY
    t.production_year DESC,
    rw.company_count DESC,
    casting_size DESC;
