WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ARRAY[mt.title] AS title_path
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT
        m.linked_movie_id AS movie_id,
        mk.title,
        mk.production_year,
        mh.title_path || mk.title
    FROM
        movie_link m
    JOIN
        aka_title mk ON m.linked_movie_id = mk.id
    JOIN
        movie_hierarchy mh ON m.movie_id = mh.movie_id
)

SELECT
    a.name AS actor_name,
    COALESCE(ARRAY_AGG(DISTINCT mk.title ORDER BY mk.production_year), '{}') AS movies_played,
    COUNT(DISTINCT vk.title) AS movie_count,
    MAX(mk.production_year) AS last_movie_year,
    MIN(CASE WHEN mk.production_year IS NOT NULL THEN mk.production_year END) AS first_movie_year,
    COUNT(DISTINCT CASE WHEN mk.production_year < 2000 THEN mk.id END) AS pre_2000_movies,
    STRING_AGG(DISTINCT mk.title || ' (' || mk.production_year || ')', ', ') AS detailed_movies,
    (SELECT COUNT(*)
     FROM movie_companies mc
     WHERE mc.movie_id = mk.id AND mc.company_id IN (SELECT id FROM company_name WHERE country_code = 'USA')) AS us_company_count
FROM
    aka_name a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    aka_title mk ON ci.movie_id = mk.id
LEFT JOIN
    movie_keyword mk2 ON mk.id = mk2.movie_id
LEFT JOIN
    keyword k ON mk2.keyword_id = k.id
LEFT JOIN
    movie_hierarchy mh ON mk.id = mh.movie_id
LEFT JOIN
    (SELECT DISTINCT ON (movie_id) * FROM movie_info_idx WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'Genre')) mi ON mk.id = mi.movie_id
WHERE
    a.name IS NOT NULL
AND
    mk.production_year IS NOT NULL
GROUP BY
    a.id
HAVING
    COUNT(DISTINCT mk.title) > 3
ORDER BY
    last_movie_year DESC,
    first_movie_year ASC
LIMIT 10;

