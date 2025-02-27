
WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        NULL AS parent_movie_id,
        1 AS depth
    FROM
        aka_title mt
    WHERE
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT
        ct.movie_id,
        mt.title,
        mh.movie_id AS parent_movie_id,
        mh.depth + 1
    FROM
        complete_cast ct
    JOIN
        movie_hierarchy mh ON ct.movie_id = mh.parent_movie_id
    JOIN
        aka_title mt ON ct.movie_id = mt.id
),
ranked_cast AS (
    SELECT
        ci.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM
        cast_info ci
    JOIN
        aka_name a ON ci.person_id = a.person_id
), 
keyword_movie_info AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
), 
movie_companies_info AS (
    SELECT
        mc.movie_id,
        COUNT(mc.company_id) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names
    FROM
        movie_companies mc
    JOIN
        company_name c ON mc.company_id = c.id
    GROUP BY
        mc.movie_id
)

SELECT
    mh.movie_id,
    mh.title,
    mh.parent_movie_id,
    mh.depth,
    rc.actor_name,
    rc.role_rank,
    kmi.keywords,
    mci.company_count,
    mci.company_names
FROM
    movie_hierarchy mh
LEFT JOIN
    ranked_cast rc ON mh.movie_id = rc.movie_id
LEFT JOIN
    keyword_movie_info kmi ON mh.movie_id = kmi.movie_id
LEFT JOIN
    movie_companies_info mci ON mh.movie_id = mci.movie_id
WHERE
    mh.depth <= 3 AND
    (rc.role_rank IS NULL OR rc.role_rank <= 3) 
ORDER BY
    mh.depth, 
    mh.movie_id, 
    rc.role_rank;
