WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        COALESCE(eo.title, 'N/A') AS episode_of,
        mt.season_nr,
        mt.episode_nr,
        1 AS level
    FROM
        aka_title AS mt
    LEFT JOIN
        aka_title AS eo ON mt.episode_of_id = eo.id
    WHERE
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT
        mt.id AS movie_id,
        mt.title,
        COALESCE(eo.title, 'N/A') AS episode_of,
        mt.season_nr,
        mt.episode_nr,
        mh.level + 1
    FROM
        aka_title AS mt
    JOIN
        movie_hierarchy AS mh ON mt.episode_of_id = mh.movie_id
),
cast_with_roles AS (
    SELECT
        ci.movie_id,
        ak.name,
        ct.kind AS role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ak.name) AS role_order
    FROM
        cast_info AS ci
    JOIN
        aka_name AS ak ON ci.person_id = ak.person_id
    JOIN
        comp_cast_type AS ct ON ci.person_role_id = ct.id
),
filtered_keywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(kw.keyword, ', ') AS keywords
    FROM
        movie_keyword AS mk
    JOIN
        keyword AS kw ON mk.keyword_id = kw.id
    GROUP BY
        mk.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.episode_of,
    mh.season_nr,
    mh.episode_nr,
    COALESCE(ck.name, 'Unknown') AS character_name,
    cr.role,
    COALESCE(fk.keywords, 'No keywords') AS keywords,
    MAX(CASE WHEN ak.name IS NULL THEN 'Anonymous' ELSE ak.name END) AS cast_names
FROM
    movie_hierarchy AS mh
LEFT JOIN
    cast_with_roles AS cr ON mh.movie_id = cr.movie_id
LEFT JOIN
    filtered_keywords AS fk ON mh.movie_id = fk.movie_id
LEFT JOIN
    aka_name AS ck ON cr.movie_id = ck.person_id AND cr.role_order = 1
GROUP BY
    mh.movie_id, mh.title, mh.episode_of, mh.season_nr, mh.episode_nr, cr.role, ck.name, fk.keywords
HAVING
    COUNT(DISTINCT cr.role) > 1
ORDER BY
    mh.production_year DESC NULLS LAST, mh.title;
