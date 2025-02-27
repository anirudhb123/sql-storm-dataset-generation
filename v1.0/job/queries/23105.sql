WITH RECURSIVE title_hierarchy AS (
    SELECT
        t.id,
        t.title,
        t.production_year,
        t.kind_id,
        0 AS depth
    FROM
        aka_title t
    WHERE
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') AND t.production_year > 2000

    UNION ALL

    SELECT
        t.id,
        t.title,
        t.production_year,
        t.kind_id,
        th.depth + 1
    FROM
        aka_title t
    JOIN
        title_hierarchy th ON t.episode_of_id = th.id
),
distinct_titles AS (
    SELECT DISTINCT
        th.id AS title_id,
        th.title,
        th.production_year,
        th.depth,
        ROW_NUMBER() OVER (PARTITION BY th.kind_id ORDER BY th.production_year DESC) AS rn
    FROM
        title_hierarchy th
),
top_titles AS (
    SELECT
        dt.title_id,
        dt.title,
        dt.production_year
    FROM
        distinct_titles dt
    WHERE
        dt.rn <= 5
),
movie_with_keywords AS (
    SELECT
        mt.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY
        mt.movie_id
)

SELECT
    mt.title AS Movie_Title,
    mt.production_year AS Year,
    mk.keywords AS Associated_Keywords,
    cn.name AS Company_Name,
    COALESCE(p.name, 'Unknown Actor') AS Leading_Actor,
    COUNT(c.id) AS Cast_Count,
    CASE WHEN mt.production_year < 2010 THEN 'Classic' ELSE 'Modern' END AS Era
FROM
    top_titles mt
LEFT JOIN
    complete_cast cc ON mt.title_id = cc.movie_id
LEFT JOIN
    cast_info c ON cc.subject_id = c.person_id AND cc.movie_id = c.movie_id
LEFT JOIN
    aka_name p ON c.person_id = p.person_id
LEFT JOIN
    movie_companies mc ON mt.title_id = mc.movie_id
LEFT JOIN
    company_name cn ON mc.company_id = cn.id
LEFT JOIN
    movie_with_keywords mk ON mt.title_id = mk.movie_id
WHERE
    mk.keywords IS NOT NULL OR p.name IS NOT NULL
GROUP BY
    mt.title, mt.production_year, mk.keywords, cn.name, p.name
HAVING
    COUNT(c.id) > 0
ORDER BY
    mt.production_year DESC, Movie_Title ASC;
