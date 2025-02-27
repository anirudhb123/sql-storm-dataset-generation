WITH movie_and_cast AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        c.person_id,
        a.name AS actor_name,
        r.role AS actor_role
    FROM
        aka_title t
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info c ON cc.subject_id = c.person_id
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        role_type r ON c.role_id = r.id
    WHERE
        t.production_year >= 2000
),
keyword_and_info AS (
    SELECT
        m.movie_id,
        m.movie_title,
        k.keyword
    FROM
        movie_keyword mk
    JOIN
        movie_info mi ON mk.movie_id = mi.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        title m ON mk.movie_id = m.id
    WHERE
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget') -- Assuming 'budget' is the desired info_type
)
SELECT
    mac.movie_title,
    mac.production_year,
    mci.keyword,
    STRING_AGG(DISTINCT mac.actor_name, ', ') AS cast_list
FROM
    movie_and_cast mac
JOIN
    keyword_and_info mci ON mac.movie_id = mci.movie_id
GROUP BY
    mac.movie_title,
    mac.production_year,
    mci.keyword
ORDER BY
    mac.production_year DESC,
    mac.movie_title;
