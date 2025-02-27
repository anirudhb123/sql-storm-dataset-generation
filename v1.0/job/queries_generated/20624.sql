WITH RECURSIVE movie_tree AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        COALESCE(mt.production_year, 0) AS production_year,
        1 AS depth
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT
        mc.linked_movie_id AS movie_id,
        m.title,
        COALESCE(m.production_year, 0) AS production_year,
        t.depth + 1 AS depth
    FROM
        movie_link mc
    JOIN
        movie_tree t ON mc.movie_id = t.movie_id
    JOIN
        aka_title m ON mc.linked_movie_id = m.id
),
cast_details AS (
    SELECT
        ak.person_id,
        ak.name,
        c.movie_id,
        ct.kind AS role_type,
        RANK() OVER (PARTITION BY c.movie_id ORDER BY ct.kind) AS role_rank
    FROM
        aka_name ak
    JOIN
        cast_info c ON ak.person_id = c.person_id
    JOIN
        role_type ct ON c.role_id = ct.id
),
keyword_summary AS (
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
),
full_details AS (
    SELECT
        mt.movie_id,
        mt.title,
        mt.production_year,
        cd.person_id,
        cd.name AS actor_name,
        cd.role_type,
        ks.keywords,
        ROW_NUMBER() OVER (PARTITION BY mt.movie_id ORDER BY cd.role_rank) AS actor_rank
    FROM
        movie_tree mt
    LEFT JOIN
        cast_details cd ON mt.movie_id = cd.movie_id
    LEFT JOIN
        keyword_summary ks ON mt.movie_id = ks.movie_id
)
SELECT
    movie_id,
    title,
    production_year,
    COALESCE(actor_name, 'No Cast') AS actor_name,
    COALESCE(role_type, 'Unknown Role') AS role_type,
    COALESCE(keywords, 'No Keywords') AS keywords,
    CASE
        WHEN actor_rank BETWEEN 1 AND 3 THEN 'Top Cast'
        WHEN actor_rank IS NULL THEN 'No Actor'
        ELSE 'Supporting Cast'
    END AS cast_type,
    depth
FROM
    full_details
WHERE 
    (production_year BETWEEN 2000 AND 2023 OR production_year = 0)
    AND (LOWER(title) LIKE '%adventure%' OR keywords IS NULL)
ORDER BY
    production_year DESC,
    depth ASC,
    cast_type;
