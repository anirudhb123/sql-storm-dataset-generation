WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        COALESCE(ct.kind, 'Unknown') AS company_kind,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS production_rank
    FROM
        aka_title mt
    LEFT JOIN
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN
        company_type ct ON mc.company_type_id = ct.id
    WHERE
        mt.production_year IS NOT NULL
        AND mt.title IS NOT NULL
),
actor_movie_counts AS (
    SELECT
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM
        cast_info ci
    GROUP BY
        ci.person_id
),
highest_movie_count AS (
    SELECT
        person_id,
        movie_count,
        ROW_NUMBER() OVER (ORDER BY movie_count DESC) AS rn
    FROM
        actor_movie_counts
    WHERE
        movie_count > 1
),
movie_info_ext AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, ', ') AS info_details,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_info mi
    LEFT JOIN 
        movie_keyword mk ON mi.movie_id = mk.movie_id
    GROUP BY 
        mi.movie_id
)

SELECT
    mh.movie_id,
    mh.title,
    mh.company_kind,
    mh.production_year,
    mh.production_rank,
    COALESCE(hmc.movie_count, 0) AS actor_count,
    mie.info_details,
    mie.keyword_count
FROM 
    movie_hierarchy mh
LEFT JOIN 
    highest_movie_count hmc ON mh.movie_id IN (
        SELECT movie_id 
        FROM cast_info 
        WHERE person_id = hmc.person_id
    )
LEFT JOIN
    movie_info_ext mie ON mh.movie_id = mie.movie_id
WHERE
    mh.production_year BETWEEN 2000 AND 2023
    AND mh.company_kind IS NOT NULL
    AND (mh.production_rank <= 5 OR hmc.movie_count IS NULL)
ORDER BY
    mh.production_year DESC,
    mh.title ASC
LIMIT 50;
