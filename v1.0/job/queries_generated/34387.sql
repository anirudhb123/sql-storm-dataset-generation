WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        0 AS level
    FROM
        aka_title m
    WHERE
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        mh.level + 1
    FROM
        aka_title m
    JOIN
        movie_link ml ON ml.linked_movie_id = m.id
    JOIN
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
),
ActorStats AS (
    SELECT
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS total_movies,
        COUNT(DISTINCT CASE WHEN c.nr_order = 1 THEN c.movie_id END) AS lead_roles
    FROM
        cast_info c
    JOIN
        aka_name a ON a.person_id = c.person_id
    GROUP BY
        a.person_id
),
TopActors AS (
    SELECT
        a.id,
        a.name,
        COALESCE(s.total_movies, 0) AS total_movies,
        COALESCE(s.lead_roles, 0) AS lead_roles,
        ROW_NUMBER() OVER (ORDER BY COALESCE(s.lead_roles, 0) DESC, COALESCE(s.total_movies, 0) DESC) AS actor_rank
    FROM
        aka_name a
    LEFT JOIN
        ActorStats s ON a.person_id = s.person_id
)
SELECT
    m.movie_id,
    m.movie_title,
    a.name AS actor_name,
    t.kind AS movie_kind,
    COUNT(DISTINCT kw.keyword) AS keyword_count,
    mh.level
FROM
    MovieHierarchy mh
JOIN
    movie_info mi ON mi.movie_id = mh.movie_id
JOIN
    title t ON t.id = mi.movie_id
JOIN
    cast_info c ON c.movie_id = mh.movie_id
JOIN
    aka_name a ON a.person_id = c.person_id
LEFT JOIN
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN
    keyword kw ON kw.id = mk.keyword_id
WHERE
    mh.level <= 1
GROUP BY
    m.movie_id, m.movie_title, a.name, t.kind, mh.level
HAVING
    COUNT(DISTINCT kw.keyword) > 3
ORDER BY
    mh.level, actor_rank
LIMIT 50;
