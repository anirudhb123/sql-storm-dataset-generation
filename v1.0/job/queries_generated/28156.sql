WITH movie_keywords AS (
    SELECT
        mt.id AS movie_id,
        COALESCE(array_agg(DISTINCT mk.keyword) FILTER (WHERE mk.keyword IS NOT NULL), '{}') AS keywords
    FROM
        movie_keyword mk
    JOIN
        aka_title mt ON mt.id = mk.movie_id
    GROUP BY
        mt.id
), cast_roles AS (
    SELECT
        c.movie_id,
        COALESCE(array_agg(DISTINCT r.role) FILTER (WHERE r.role IS NOT NULL), '{}') AS roles
    FROM
        cast_info c
    JOIN
        role_type r ON r.id = c.person_role_id
    GROUP BY
        c.movie_id
), movie_details AS (
    SELECT
        at.id AS movie_id,
        at.title,
        at.production_year,
        ak.name AS director_name,
        mk.keywords,
        cr.roles
    FROM
        aka_title at
    LEFT JOIN
        complete_cast cc ON cc.movie_id = at.id
    LEFT JOIN
        aka_name ak ON ak.person_id = (SELECT person_id FROM cast_info ci WHERE ci.movie_id = at.id AND ci.person_role_id = (SELECT id FROM role_type WHERE role = 'director') LIMIT 1)
    LEFT JOIN
        movie_keywords mk ON mk.movie_id = at.id
    LEFT JOIN
        cast_roles cr ON cr.movie_id = at.id
    WHERE
        at.production_year >= 2000
    ORDER BY
        at.production_year DESC
)
SELECT
    md.movie_id,
    md.title,
    md.production_year,
    md.director_name,
    md.keywords,
    md.roles,
    LENGTH(md.title) AS title_length,
    LENGTH(md.director_name) AS director_length,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = md.movie_id) AS info_count
FROM
    movie_details md
WHERE
    md.keywords && ARRAY['Drama', 'Action']  -- Filtering for movies that have 'Drama' or 'Action' in their keywords
    AND md.roles @> ARRAY['Lead']             -- Ensuring that at least one role of 'Lead' exists
ORDER BY
    title_length DESC, production_year ASC
LIMIT 50;
