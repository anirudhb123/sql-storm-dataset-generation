WITH RankedMovies AS (
    SELECT
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS note_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM
        aka_title a
    LEFT JOIN
        cast_info c ON a.id = c.movie_id
    GROUP BY
        a.id, a.title, a.production_year
),
ActorDetails AS (
    SELECT
        p.name,
        a.title,
        a.production_year,
        a.actor_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY p.name) AS actor_rank
    FROM
        RankedMovies a
    JOIN
        cast_info ci ON a.title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
    JOIN
        aka_name p ON ci.person_id = p.person_id
    WHERE
        a.actor_count > 0
),
MovieInfo AS (
    SELECT
        m.title,
        m.production_year,
        GROUP_CONCAT(DISTINCT c.name) AS actor_names,
        COALESCE(m.note, 'No notes available') AS movie_note
    FROM
        aka_title m
    LEFT JOIN
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN
        aka_name c ON ci.person_id = c.person_id
    GROUP BY
        m.id, m.title, m.production_year, m.note
)

SELECT
    DISTINCT m.title,
    m.production_year,
    m.actor_names,
    md.movie_note,
    COALESCE(SUM(CASE WHEN k.keyword IS NOT NULL THEN 1 ELSE 0 END), 0) AS keyword_count
FROM
    MovieInfo m
LEFT JOIN
    movie_keyword mk ON m.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    RankedMovies r ON m.title = r.title AND m.production_year = r.production_year
WHERE
    r.actor_count > 1
AND
    m.actor_names IS NOT NULL
GROUP BY
    m.title, m.production_year, m.actor_names, md.movie_note
HAVING
    COUNT(DISTINCT k.keyword) > 0
OR
    m.production_year IS NULL
ORDER BY
    m.production_year DESC, m.title;

WITH RECURSIVE MovieLinks AS (
    SELECT
        m.id,
        m.title,
        m.linked_movie_id,
        1 AS depth
    FROM
        movie_link m
    WHERE
        m.linked_movie_id IS NOT NULL
    UNION ALL
    SELECT
        ml.id,
        m.title,
        ml.linked_movie_id,
        ml.depth + 1
    FROM
        MovieLinks ml
    JOIN
        movie_link m ON ml.linked_movie_id = m.id
    WHERE
        ml.depth < 5
)
SELECT
    DISTINCT ml.title,
    ml.depth,
    COUNT(DISTINCT m.id) AS total_links
FROM
    MovieLinks ml 
JOIN
    aka_title m ON ml.linked_movie_id = m.id
GROUP BY
    ml.title, ml.depth
HAVING
    COUNT(DISTINCT m.id) > 1
ORDER BY
    total_links DESC;
