WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COALESCE(t.season_nr, 0) AS season,
        COALESCE(t.episode_nr, 0) AS episode,
        1 AS level
    FROM
        aka_title m
    LEFT JOIN
        aka_title t ON m.id = t.episode_of_id
    WHERE
        m.production_year >= 2000  -- Focus on movies from the year 2000 onwards
    UNION ALL
    SELECT
        m.id,
        m.title,
        COALESCE(t.season_nr, 0),
        COALESCE(t.episode_nr, 0),
        h.level + 1
    FROM
        aka_title m
    JOIN
        movie_hierarchy h ON m.episode_of_id = h.movie_id
),
cast_info_with_roles AS (
    SELECT
        c.person_id,
        c.movie_id,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM
        cast_info c
    JOIN
        role_type r ON c.role_id = r.id
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        string_agg(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.season,
    mh.episode,
    COUNT(DISTINCT ci.person_id) FILTER (WHERE ci.role_order IS NOT NULL) AS num_cast_members,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    MAX(CASE WHEN ci.role= 'Director' THEN ci.person_id END) AS director_id,
    ak.name AS director_name,
    COUNT(DISTINCT ci.person_id) OVER (PARTITION BY mh.movie_id) AS total_cast_count,
    100.0 * COUNT(DISTINCT ci.person_id) / NULLIF(COUNT(DISTINCT ci.movie_id), 0) AS cast_ratio
FROM
    movie_hierarchy mh
LEFT JOIN
    cast_info_with_roles ci ON mh.movie_id = ci.movie_id
LEFT JOIN
    movie_keywords mk ON mh.movie_id = mk.movie_id
LEFT JOIN
    aka_name ak ON ci.person_id = ak.person_id
WHERE
    mh.level <= 3  -- Limit to 3 levels in the hierarchy for brevity
GROUP BY
    mh.movie_id, mh.title, mh.season, mh.episode, mk.keywords, ak.name
ORDER BY
    mh.production_year DESC NULLS LAST,
    num_cast_members DESC;
