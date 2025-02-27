WITH movie_title_year AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        t.imdb_index
    FROM 
        title t
    WHERE 
        t.production_year >= 2000
),
actor_names AS (
    SELECT
        a.person_id,
        a.name AS actor_name,
        a.imdb_index AS actor_imdb_index
    FROM
        aka_name a
    WHERE 
        a.name ILIKE '%John%' OR a.name ILIKE '%Jane%'
),
cast_details AS (
    SELECT
        c.movie_id,
        c.person_id,
        c.nr_order,
        r.role AS role
    FROM
        cast_info c
    JOIN
        role_type r ON c.role_id = r.id
),
movies_with_actors AS (
    SELECT
        m.title_id,
        m.title,
        m.production_year,
        a.actor_name,
        a.actor_imdb_index,
        cd.nr_order,
        cd.role
    FROM
        movie_title_year m
    JOIN
        cast_details cd ON m.title_id = cd.movie_id
    JOIN
        actor_names a ON cd.person_id = a.person_id
),
keyword_info AS (
    SELECT
        mk.movie_id,
        k.keyword
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
)
SELECT
    m.title,
    m.production_year,
    m.actor_name,
    m.actor_imdb_index,
    m.nr_order,
    m.role,
    STRING_AGG(ki.keyword, ', ') AS keywords
FROM
    movies_with_actors m
LEFT JOIN
    keyword_info ki ON m.title_id = ki.movie_id
GROUP BY
    m.title, m.production_year, m.actor_name, m.actor_imdb_index, m.nr_order, m.role
ORDER BY
    m.production_year DESC,
    m.title ASC;
